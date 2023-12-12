# frozen_string_literal: true
module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def yield
        ::Async::Task.current.yield
        nil
      end

      def run
        job_tasks = []
        next_job_tasks = []
        source_tasks = []
        next_source_tasks = []
        first_pass = true
        Sync do
          while first_pass || job_tasks.any?
            first_pass = false

            Async do
              while (task = job_tasks.shift || spawn_job_task)
                if task.alive?
                  next_job_tasks << task
                end
              end
            end.wait
            job_tasks.concat(next_job_tasks)
            next_job_tasks.clear

            while source_tasks.any? || @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
              Async do
                while (task = source_tasks.shift || spawn_source_task)
                  if task.alive?
                    next_source_tasks << task
                  end
                end
              end
              source_tasks.concat(next_source_tasks)
              next_source_tasks.clear
            end
          end
        end
      rescue UncaughtThrowError => e
        throw e.tag, e.value
      end

      private

      def spawn_job_task
        if @pending_jobs.any?
          fiber_vars = get_fiber_variables
          Async do
            set_fiber_variables(fiber_vars)
            while job = @pending_jobs.shift
              job.call
            end
          end
        end
      end

      def spawn_source_task
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
          fiber_vars = get_fiber_variables
          Async do
            set_fiber_variables(fiber_vars)
            pending_sources.each(&:run_pending_keys)
          end
        end
      end
    end
  end
end
