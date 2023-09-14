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

    AsyncDataloader = Class.new(self) { self.default_nonblocking = true }

    def self.use(schema, nonblocking: nil)
      schema.dataloader_class = if nonblocking
        AsyncDataloader
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
      if use_fiber_resume?
        Fiber.yield
      else
        parent_fiber = Thread.current[:parent_fiber]
        parent_fiber.transfer
      end
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
        source_instance.pending.merge!(pending)
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

          while (f = job_fibers.shift || spawn_job_fiber)
            if f.alive?
              finished = run_fiber(f)
              if !finished
                next_job_fibers << f
              end
            end
          end

          if job_fibers.empty?
            any_pending_sources = true
            while any_pending_sources
              while (f = source_fibers.shift || spawn_source_fiber)
                if f.alive?
                  finished = run_fiber(f)
                  if !finished
                    next_source_fibers << f
                  end
                end
              end
              Fiber.scheduler&.run
              source_fibers.concat(next_source_fibers)
              next_source_fibers.clear

              any_pending_sources = @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
            end
          end
          Fiber.scheduler&.run
          job_fibers.concat(next_job_fibers)
          next_job_fibers.clear
        end
      end

      run_fiber(manager)

    rescue UncaughtThrowError => e
      throw e.tag, e.value
    end

    def run_fiber(f)
      if use_fiber_resume?
        f.resume
      else
        f.transfer
      end
    end

    def spawn_fiber
      st = get_fiber_state
      parent_fiber = use_fiber_resume? ? nil : Fiber.current
      Fiber.new {
        set_fiber_state(st)
        if parent_fiber
          Thread.current[:parent_fiber] = parent_fiber
        end
        yield
        # With `.transfer`, you have to explicitly pass back to the parent --
        # if the fiber is allowed to terminate normally, control is passed to the main fiber instead.
        if parent_fiber
          parent_fiber.transfer(true)
        else
          true
        end
      }
    end


    def get_fiber_state
      fiber_locals = {}

      Thread.current.keys.each do |fiber_var_key|
        # This variable should be fresh in each new fiber
        if fiber_var_key != :__graphql_runtime_info
          fiber_locals[fiber_var_key] = Thread.current[fiber_var_key]
        end
      end

      fiber_locals
    end

    def set_fiber_state(state)
      state.each { |k, v| Thread.current[k] = v }
    end

    private

    def use_fiber_resume?
      (defined?(::DummyScheduler) && Fiber.scheduler.is_a?(::DummyScheduler)) ||
        (defined?(::Evt) && Fiber.scheduler.is_a?(::Evt::Scheduler)) ||
        (defined?(::Libev) && Fiber.scheduler.is_a?(::Libev::Scheduler))
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
