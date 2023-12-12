# frozen_string_literal: true
module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def yield
        Fiber.scheduler.yield
        nil
      end

      def run
        job_fibers = []
        next_job_fibers = []
        source_fibers = []
        next_source_fibers = []
        first_pass = true
        Sync do
          while first_pass || job_fibers.any?
            first_pass = false

            Async do
              while (f = job_fibers.shift || spawn_job_fiber)
                if f.alive?
                  next_job_fibers << f
                end
              end
            end.wait
            job_fibers.concat(next_job_fibers)
            next_job_fibers.clear

            while source_fibers.any? || @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
              Async do
                while (f = source_fibers.shift || spawn_source_fiber)
                  if f.alive?
                    next_source_fibers << f
                  end
                end
              end
              source_fibers.concat(next_source_fibers)
              next_source_fibers.clear
            end
          end
        end

      rescue UncaughtThrowError => e
        throw e.tag, e.value
      end

      def spawn_task
        fiber_vars = get_fiber_variables
        Async {
          set_fiber_variables(fiber_vars)
          yield
        }
      end

      private

      def spawn_job_fiber
        if @pending_jobs.any?
          spawn_task do
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
          spawn_task do
            pending_sources.each(&:run_pending_keys)
          end
        end
      end
    end
  end
end
