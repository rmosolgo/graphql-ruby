# frozen_string_literal: true
module GraphQL
  class Dataloader
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
    # @api private
    # @see Dataloader#run
    class Run
      def initialize(dataloader:)
        @dataloader = dataloader
        @total_fiber_limit = dataloader.fiber_limit || Float::INFINITY
        if @total_fiber_limit < 3
          raise ArgumentError, "Dataloader fiber limit is too low (#{@total_fiber_limit}), it must be at least 3"
        end
        # Make sure that some fibers are reserved for running sources
        @jobs_fiber_limit = @total_fiber_limit - 2
        @nonblocking = dataloader.nonblocking?
        @pending_jobs = dataloader.pending_jobs
        @pending_sources = dataloader.pending_sources

        @pending_job_fibers = []
        @next_job_fibers = []

        @pending_source_fibers = []
        @next_source_fibers = []
      end

      def fiber_count
        @pending_job_fibers.size +
          @next_job_fibers.size +
          @pending_source_fibers.size +
          @next_source_fibers.size
      end

      def run
        if @nonblocking && !Fiber.scheduler
          raise "`nonblocking: true` requires `Fiber.scheduler`, assign one with `Fiber.set_scheduler(...)` before executing GraphQL."
        end

        first_pass = true
        while first_pass || (f = @pending_job_fibers.shift)
          if first_pass
            first_pass = false
          else
            # These fibers were previously waiting for sources to load data,
            # resume them. (They might wait again, in which case, re-enqueue them.)
            resume_once(f, @next_job_fibers)
          end

          while @pending_jobs.any? && fiber_count < @jobs_fiber_limit
            # Create a Fiber to consume jobs until one of the jobs yields or jobs run out
            f = spawn_fiber {
              while (job = @pending_jobs.shift)
                job.call
              end
            }
            # In this case, if `f` is still alive, the job yielded.
            # Queue it up to run again after we load whatever it's waiting for.
            resume_once(f, @next_job_fibers)
          end

          if @pending_job_fibers.empty? || fiber_count >= @jobs_fiber_limit
            # Now, run all Sources which have become pending _before_ resuming GraphQL execution.
            # Sources might queue up other Sources, which is fine -- those will also run before resuming execution.
            #
            # This is where an evented approach would be even better -- can we tell which
            # fibers are ready to continue, and continue execution there?
            #
            first_source_pass = true
            while first_source_pass || (source_fiber = @pending_source_fibers.shift)
              if first_source_pass
                first_source_pass = false
              elsif source_fiber
                resume_once(source_fiber, @next_source_fibers)
              end

              while @pending_sources.any? && fiber_count < @total_fiber_limit
                f = spawn_fiber do
                  while (source = @pending_sources.shift)
                    source.run_pending_keys
                  end
                end
                resume_once(f, @next_source_fibers)
              end

              if @pending_source_fibers.empty? || fiber_count >= @total_fiber_limit
                join_queues(@pending_source_fibers, @next_source_fibers)
              end
            end
            # Move newly-enqueued Fibers on to the list to be resumed.
            # Clear out the list of next-round Fibers, so that
            # any Fibers that pause can be put on it.
            join_queues(@pending_job_fibers, @next_job_fibers)
          end
        end

        if @pending_jobs.any?
          raise "Invariant: #{@pending_jobs.size} pending jobs"
        elsif @pending_job_fibers.any?
          raise "Invariant: #{@pending_job_fibers.size} pending fibers"
        elsif @next_job_fibers.any?
          raise "Invariant: #{@next_job_fibers.size} next fibers"
        elsif @pending_sources.any?
          raise "Invariant: #{@pending_sources.size} pending sources"
        elsif @pending_source_fibers.any?
          raise "Invariant: #{@pending_source_fibers.size} pending source fibers"
        elsif @next_source_fibers.any?
          raise "Invariant: #{@next_source_fibers.size} next source fibers"
        end
        nil
      end

      private

      def join_queues(previous_queue, next_queue)
        if @nonblocking
          Fiber.scheduler.run
          next_queue.select!(&:alive?)
        end
        previous_queue.concat(next_queue)
        next_queue.clear
      end


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
end
