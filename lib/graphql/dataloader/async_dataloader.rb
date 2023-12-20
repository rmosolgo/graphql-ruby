# frozen_string_literal: true
module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def yield
        Thread.current[:graphql_dataloader_next_tick].wait
        nil
      end

      def run
        job_tasks = []
        next_job_tasks = []
        source_tasks = []
        next_source_tasks = []
        first_pass = true
        jobs_condition = Async::Condition.new
        sources_condition = Async::Condition.new
        Sync do |root_task|
          while first_pass || job_tasks.any?
            first_pass = false

            root_task.async do |jobs_task|
              while (task = job_tasks.shift || spawn_job_task(jobs_task, jobs_condition))
                if task.alive?
                  next_job_tasks << task
                elsif task.failed?
                  # re-raise a raised error -
                  # this also covers errors from sources since
                  # these jobs wait for sources as needed.
                  task.wait
                end
              end
            end.wait
            job_tasks.concat(next_job_tasks)
            next_job_tasks.clear

            while source_tasks.any? || @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
              root_task.async do |sources_loop_task|
                while (task = source_tasks.shift || spawn_source_task(sources_loop_task, sources_condition))
                  if task.alive?
                    next_source_tasks << task
                  end
                end
              end.wait
              sources_condition.signal
              source_tasks.concat(next_source_tasks)
              next_source_tasks.clear
            end
            jobs_condition.signal
          end
        end
      rescue UncaughtThrowError => e
        throw e.tag, e.value
      end

      private

      def spawn_job_task(parent_task, condition)
        if @pending_jobs.any?
          fiber_vars = get_fiber_variables
          parent_task.async do |t|
            set_fiber_variables(fiber_vars)
            Thread.current[:graphql_dataloader_next_tick] = condition
            while job = @pending_jobs.shift
              job.call
            end
          end
        end
      end

      def spawn_source_task(parent_task, condition)
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
          parent_task.async do
            set_fiber_variables(fiber_vars)
            Thread.current[:graphql_dataloader_next_tick] = condition
            pending_sources.each(&:run_pending_keys)
          end
        end
      end
    end
  end
end
