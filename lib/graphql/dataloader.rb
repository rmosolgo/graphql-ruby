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
      attr_accessor :default_fiber_limit
    end

    AsyncDataloader = Class.new(self) { self.default_nonblocking = true }

    def self.use(schema, nonblocking: nil, fiber_limit: nil)
      dataloader_class = if nonblocking
        AsyncDataloader
      else
        self
      end

      if fiber_limit
        dataloader_class = Class.new(dataloader_class)
        dataloader_class.default_fiber_limit = fiber_limit
      end

      schema.dataloader_class = dataloader_class
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
      @pending_sources = []
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

    def enqueue_pending_source(source)
      if !@pending_sources.include?(source)
        @pending_sources << source
      end
      nil
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

    # Use a self-contained queue for the work in the block.
    def run_isolated
      prev_queue = @pending_jobs
      prev_source_queue = @pending_sources
      prev_pending_keys = {}
      @source_cache.each do |source_class, batched_sources|
        batched_sources.each do |batch_args, batched_source_instance|
          if batched_source_instance.pending?
            prev_pending_keys[batched_source_instance] = batched_source_instance.pending_keys.dup
            batched_source_instance.pending_keys.clear
          end
        end
      end

      @pending_jobs = []
      @pending_sources = []
      res = nil
      # Make sure the block is inside a Fiber, so it can `Fiber.yield`
      append_job {
        res = yield
      }
      run
      res
    ensure
      @pending_jobs = prev_queue
      @pending_sources = prev_source_queue
      prev_pending_keys.each do |source_instance, pending_keys|
        source_instance.pending_keys.concat(pending_keys)
      end
    end

    # @api private Move along, move along
    def run
      if @nonblocking && !Fiber.scheduler
        raise "`nonblocking: true` requires `Fiber.scheduler`, assign one with `Fiber.set_scheduler(...)` before executing GraphQL."
      end
      # At a high level, the algorithm is:
      #
      #  A) Inside Fibers, run jobs from the queue one-by-one
      #    - When one of the jobs yields to the dataloader (`Fiber.yield`), then that fiber will pause
      #    - In that case, if there are still pending jobs, a new Fiber will be created to run jobs
      #    - Continue until all jobs have been _started_ by a Fiber. (Any number of those Fibers may be waiting to be resumed, after their data is loaded)
      #  B) Once all known jobs have been run until they are complete or paused for data, run all pending data sources.
      #    - Similarly, create a Fiber to consume pending sources and tell them to load their data.
      #    - If one of those Fibers pauses, then create a new Fiber to continue working through remaining pending sources.
      #    - When a source causes another source to become pending, run the newly-pending source _first_, since it's a dependency of the previous one.
      #  C) After all pending sources have been completely loaded (there are no more pending sources), resume any Fibers that were waiting for data.
      #    - Those Fibers assume that source caches will have been populated with the data they were waiting for.
      #    - Those Fibers may request data from a source again, in which case they will yeilded and be added to a new pending fiber list.
      #  D) Once all pending fibers have been resumed once, return to `A` above.
      #
      # For whatever reason, the best implementation I could find was to order the steps `[D, A, B, C]`, with a special case for skipping `D`
      # on the first pass. I just couldn't find a better way to write the loops in a way that was DRY and easy to read.
      #
      pending_fibers = []
      next_fibers = []
      pending_source_fibers = []
      next_source_fibers = []
      first_pass = true

      while first_pass || (f = pending_fibers.shift)
        if first_pass
          first_pass = false
        else
          # These fibers were previously waiting for sources to load data,
          # resume them. (They might wait again, in which case, re-enqueue them.)
          resume_once(f, next_fibers)
        end

        while @pending_jobs.any?
          # Create a Fiber to consume jobs until one of the jobs yields
          # or jobs run out
          f = spawn_fiber {
            while (job = @pending_jobs.shift)
              job.call
            end
          }
          # In this case, if `f` is still alive, the job yielded.
          # Queue it up to run again after we load whatever it's waiting for.
          resume_once(f, next_fibers)
        end

        if pending_fibers.empty?
          # Now, run all Sources which have become pending _before_ resuming GraphQL execution.
          # Sources might queue up other Sources, which is fine -- those will also run before resuming execution.
          #
          # This is where an evented approach would be even better -- can we tell which
          # fibers are ready to continue, and continue execution there?
          #
          first_source_pass = true
          while first_source_pass || (source_fiber = pending_source_fibers.shift)
            if first_source_pass
              first_source_pass = false
            elsif source_fiber
              resume_once(source_fiber, next_source_fibers)
            end

            while @pending_sources.any?
              f = spawn_fiber do
                while (source = @pending_sources.shift)
                  source.run_pending_keys
                end
              end

              resume_once(f, next_source_fibers)
            end

            if pending_source_fibers.empty?
              join_queues(pending_source_fibers, next_source_fibers)
              next_source_fibers.clear
            end
          end
          # Move newly-enqueued Fibers on to the list to be resumed.
          # Clear out the list of next-round Fibers, so that
          # any Fibers that pause can be put on it.
          join_queues(pending_fibers, next_fibers)
          next_fibers.clear
        end
      end

      if @pending_jobs.any?
        raise "Invariant: #{@pending_jobs.size} pending jobs"
      elsif pending_fibers.any?
        raise "Invariant: #{pending_fibers.size} pending fibers"
      elsif next_fibers.any?
        raise "Invariant: #{next_fibers.size} next fibers"
      end
      nil
    end

    def join_queues(previous_queue, next_queue)
      if @nonblocking
        Fiber.scheduler.run
        next_queue.select!(&:alive?)
      end
      previous_queue.concat(next_queue)
    end

    private

    def resume_once(fiber, next_queue)
      fiber.resume
      if fiber.alive?
        next_queue << fiber
      end
    rescue UncaughtThrowError => e
      throw e.tag, e.value
    end

    # Copies the thread local vars into the fiber thread local vars. Many
    # gems (such as RequestStore, MiniRacer, etc.) rely on thread local vars
    # to keep track of execution context, and without this they do not
    # behave as expected.
    #
    # @see https://github.com/rmosolgo/graphql-ruby/issues/3449
    def spawn_fiber
      fiber_locals = {}

      Thread.current.keys.each do |fiber_var_key|
        fiber_locals[fiber_var_key] = Thread.current[fiber_var_key]
      end

      if @nonblocking
        Fiber.new(blocking: false) do
          fiber_locals.each { |k, v| Thread.current[k] = v }
          yield
        end
      else
        Fiber.new do
          fiber_locals.each { |k, v| Thread.current[k] = v }
          yield
        end
      end
    end
  end
end
