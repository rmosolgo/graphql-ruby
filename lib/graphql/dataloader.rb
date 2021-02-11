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
    def self.use(schema)
      schema.dataloader_class = self
    end

    def initialize
      @source_cache = Hash.new { |h, source_class| h[source_class] = Hash.new { |h2, batch_parameters|
          source = source_class.new(*batch_parameters)
          source.setup(self)
          h2[batch_parameters] = source
        }
      }
      @pending_jobs = []
    end

    # Get a Source instance from this dataloader, for calling `.load(...)` or `.request(...)` on.
    #
    # @param source_class [Class<GraphQL::Dataloader::Source]
    # @param batch_parameters [Array<Object>]
    # @return [GraphQL::Dataloader::Source] An instance of {source_class}, initialized with `self, *batch_parameters`,
    #   and cached for the lifetime of this {Multiplex}.
    def with(source_class, *batch_parameters)
      @source_cache[source_class][batch_parameters]
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

    # @api private Move along, move along
    def run
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
      first_pass = true

      while first_pass || (f = pending_fibers.shift)
        if first_pass
          first_pass = false
        else
          # These fibers were previously waiting for sources to load data,
          # resume them. (They might wait again, in which case, re-enqueue them.)
          resume(f)
          if f.alive?
            next_fibers << f
          end
        end

        while @pending_jobs.any?
          # Create a Fiber to consume jobs until one of the jobs yields
          # or jobs run out
          f = Fiber.new {
            while (job = @pending_jobs.shift)
              job.call
            end
          }
          resume(f)
          # In this case, the job yielded. Queue it up to run again after
          # we load whatever it's waiting for.
          if f.alive?
            next_fibers << f
          end
        end

        if pending_fibers.empty?
          # Now, run all Sources which have become pending _before_ resuming GraphQL execution.
          # Sources might queue up other Sources, which is fine -- those will also run before resuming execution.
          #
          # This is where an evented approach would be even better -- can we tell which
          # fibers are ready to continue, and continue execution there?
          #
          source_fiber_stack = if (first_source_fiber = create_source_fiber)
            [first_source_fiber]
          else
            nil
          end

          if source_fiber_stack
            # Use a stack with `.pop` here so that when a source causes another source to become pending,
            # that newly-pending source will run _before_ the one that depends on it.
            # (See below where the old fiber is pushed to the stack, then the new fiber is pushed on the stack.)
            while (outer_source_fiber = source_fiber_stack.pop)
              resume(outer_source_fiber)

              if outer_source_fiber.alive?
                source_fiber_stack << outer_source_fiber
              end
              # If this source caused more sources to become pending, run those before running this one again:
              next_source_fiber = create_source_fiber
              if next_source_fiber
                source_fiber_stack << next_source_fiber
              end
            end
          end
          # Move newly-enqueued Fibers on to the list to be resumed.
          # Clear out the list of next-round Fibers, so that
          # any Fibers that pause can be put on it.
          pending_fibers.concat(next_fibers)
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

    private

    # If there are pending sources, return a fiber for running them.
    # Otherwise, return `nil`.
    #
    # @return [Fiber, nil]
    def create_source_fiber
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
        # By passing the whole array into this Fiber, it's possible that we set ourselves up for a bunch of no-ops.
        # For example, if you have sources `[a, b, c]`, and `a` is loaded, then `b` yields to wait for `d`, then
        # the next fiber would be dispatched with `[c, d]`. It would fulfill `c`, then `d`, then eventually
        # the previous fiber would start up again. `c` would no longer be pending, but it would still receive `.run_pending_keys`.
        # That method is short-circuited since it isn't pending any more, but it's still a waste.
        #
        # This design could probably be improved by maintaining a `@pending_sources` queue which is shared by the fibers,
        # similar to `@pending_jobs`. That way, when a fiber is resumed, it would never pick up work that was finished by a different fiber.
        source_fiber = Fiber.new do
          pending_sources.each(&:run_pending_keys)
        end
      end

      source_fiber
    end

    def resume(fiber)
      fiber.resume
    rescue UncaughtThrowError => e
      throw e.tag, e.value
    end
  end
end
