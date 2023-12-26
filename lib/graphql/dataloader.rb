# frozen_string_literal: true

require "graphql/dataloader/null_dataloader"
require "graphql/dataloader/request"
require "graphql/dataloader/request_all"
require "graphql/dataloader/source"

module GraphQL
  # This plugin supports Fiber-based concurrency, along with {GraphQL::Dataloader::Source}.
  #
  # @example Installing Dataloader
  #
  #   class MySchema < GraphQL::Schema
  #     use GraphQL::Dataloader
  #   end
  #
  # @example Waiting for batch-loaded data in a GraphQL field
  #
  #   field :team, Types::Team, null: true
  #
  #   def team
  #     dataloader.with(Sources::Record, Team).load(object.team_id)
  #   end
  #
  class Dataloader
    class << self
      attr_accessor :default_nonblocking
    end

    NonblockingDataloader = Class.new(self) { self.default_nonblocking = true }

    def self.use(schema, nonblocking: nil)
      schema.dataloader_class = if nonblocking
        warn("`nonblocking: true` is deprecated from `GraphQL::Dataloader`, please use `GraphQL::Dataloader::AsyncDataloader` instead. Docs: https://graphql-ruby.org/dataloader/async_dataloader.")
        NonblockingDataloader
      else
        self
      end
    end

    # Call the block with a Dataloader instance,
    # then run all enqueued jobs and return the result of the block.
    def self.with_dataloading(&block)
      dataloader = self.new
      result = nil
      dataloader.append_job {
        result = block.call(dataloader)
      }
      dataloader.run
      result
    end

    def initialize(nonblocking: self.class.default_nonblocking)
      @source_cache = Hash.new { |h, k| h[k] = {} }
      @pending_jobs = []
      if !nonblocking.nil?
        @nonblocking = nonblocking
      end
    end

    def nonblocking?
      @nonblocking
    end

    # This is called before the fiber is spawned, from the parent context (i.e. from
    # the thread or fiber that it is scheduled from).
    #
    # @return [Hash<Symbol, Object>] Current fiber-local variables
    def get_fiber_variables
      fiber_vars = {}
      Thread.current.keys.each do |fiber_var_key|
        # This variable should be fresh in each new fiber
        if fiber_var_key != :__graphql_runtime_info
          fiber_vars[fiber_var_key] = Thread.current[fiber_var_key]
        end
      end
      fiber_vars
    end

    # Set up the fiber variables in a new fiber.
    #
    # This is called within the fiber, right after it is spawned.
    #
    # @param vars [Hash<Symbol, Object>] Fiber-local variables from {get_fiber_variables}
    # @return [void]
    def set_fiber_variables(vars)
      vars.each { |k, v| Thread.current[k] = v }
      nil
    end

    # Get a Source instance from this dataloader, for calling `.load(...)` or `.request(...)` on.
    #
    # @param source_class [Class<GraphQL::Dataloader::Source]
    # @param batch_parameters [Array<Object>]
    # @return [GraphQL::Dataloader::Source] An instance of {source_class}, initialized with `self, *batch_parameters`,
    #   and cached for the lifetime of this {Multiplex}.
    if RUBY_VERSION < "3" || RUBY_ENGINE != "ruby" # truffle-ruby wasn't doing well with the implementation below
      def with(source_class, *batch_args)
        batch_key = source_class.batch_key_for(*batch_args)
        @source_cache[source_class][batch_key] ||= begin
          source = source_class.new(*batch_args)
          source.setup(self)
          source
        end
      end
    else
      def with(source_class, *batch_args, **batch_kwargs)
        batch_key = source_class.batch_key_for(*batch_args, **batch_kwargs)
        @source_cache[source_class][batch_key] ||= begin
          source = source_class.new(*batch_args, **batch_kwargs)
          source.setup(self)
          source
        end
      end
    end
    # Tell the dataloader that this fiber is waiting for data.
    #
    # Dataloader will resume the fiber after the requested data has been loaded (by another Fiber).
    #
    # @return [void]
    def yield
      Fiber.yield
      nil
    end

    # @api private Nothing to see here
    def append_job(&job)
      # Given a block, queue it up to be worked through when `#run` is called.
      # (If the dataloader is already running, than a Fiber will pick this up later.)
      @pending_jobs.push(job)
      nil
    end

    # Clear any already-loaded objects from {Source} caches
    # @return [void]
    def clear_cache
      @source_cache.each do |_source_class, batched_sources|
        batched_sources.each_value(&:clear_cache)
      end
      nil
    end

    # Use a self-contained queue for the work in the block.
    def run_isolated
      prev_queue = @pending_jobs
      prev_pending_keys = {}
      @source_cache.each do |source_class, batched_sources|
        batched_sources.each do |batch_args, batched_source_instance|
          if batched_source_instance.pending?
            prev_pending_keys[batched_source_instance] = batched_source_instance.pending.dup
            batched_source_instance.pending.clear
          end
        end
      end

      @pending_jobs = []
      res = nil
      # Make sure the block is inside a Fiber, so it can `Fiber.yield`
      append_job {
        res = yield
      }
      run
      res
    ensure
      @pending_jobs = prev_queue
      prev_pending_keys.each do |source_instance, pending|
        pending.each do |key, value|
          if !source_instance.results.key?(key)
            source_instance.pending[key] = value
          end
        end
      end
    end

    def run
      job_fibers = []
      next_job_fibers = []
      source_fibers = []
      next_source_fibers = []
      first_pass = true
      manager = spawn_fiber do
        while first_pass || job_fibers.any?
          first_pass = false

          while (f = (job_fibers.shift || spawn_job_fiber))
            if f.alive?
              finished = run_fiber(f)
              if !finished
                next_job_fibers << f
              end
            end
          end
          join_queues(job_fibers, next_job_fibers)

          while source_fibers.any? || @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
            while (f = source_fibers.shift || spawn_source_fiber)
              if f.alive?
                finished = run_fiber(f)
                if !finished
                  next_source_fibers << f
                end
              end
            end
            join_queues(source_fibers, next_source_fibers)
          end
        end
      end

      run_fiber(manager)

      if manager.alive?
        raise "Invariant: Manager fiber didn't terminate properly."
      end

      if job_fibers.any?
        raise "Invariant: job fibers should have exited but #{job_fibers.size} remained"
      end
      if source_fibers.any?
        raise "Invariant: source fibers should have exited but #{source_fibers.size} remained"
      end
    rescue UncaughtThrowError => e
      throw e.tag, e.value
    end

    def run_fiber(f)
      f.resume
    end

    def spawn_fiber
      fiber_vars = get_fiber_variables
      Fiber.new(blocking: !@nonblocking) {
        set_fiber_variables(fiber_vars)
        yield
        # With `.transfer`, you have to explicitly pass back to the parent --
        # if the fiber is allowed to terminate normally, control is passed to the main fiber instead.
        true
      }
    end

    private

    def join_queues(prev_queue, new_queue)
      @nonblocking && Fiber.scheduler.run
      prev_queue.concat(new_queue)
      new_queue.clear
    end

    def spawn_job_fiber
      if @pending_jobs.any?
        spawn_fiber do
          while job = @pending_jobs.shift
            job.call
          end
        end
      end
    end

    def spawn_source_fiber
      pending_sources = nil
      @source_cache.each_value do |source_by_batch_params|
        source_by_batch_params.each_value do |source|
          if source.pending?
            pending_sources ||= []
            pending_sources << source
          end
        end
      end

      if pending_sources
        spawn_fiber do
          pending_sources.each(&:run_pending_keys)
        end
      end
    end
  end
end

require "graphql/dataloader/async_dataloader"
