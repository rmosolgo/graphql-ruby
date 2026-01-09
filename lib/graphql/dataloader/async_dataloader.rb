# frozen_string_literal: true
module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def yield(source = Fiber[:__graphql_current_dataloader_source])
        trace = Fiber[:__graphql_current_multiplex]&.current_trace
        trace&.dataloader_fiber_yield(source)
        Fiber[:graphql_dataloader_next_tick].wait
        trace&.dataloader_fiber_resume(source)
        nil
      end

      def run(trace_query_lazy: nil)
        trace = Fiber[:__graphql_current_multiplex]&.current_trace
        jobs_fiber_limit, total_fiber_limit = calculate_fiber_limit
        job_fibers = []
        next_job_fibers = []
        source_tasks = []
        next_source_tasks = []
        first_pass = true

        sources_condition = Async::Condition.new
        jobs_condition = Async::Condition.new
        trace&.begin_dataloader(self)
        fiber_vars = get_fiber_variables
        raised_error = nil
        Sync do |root_task|
          while first_pass || !job_fibers.empty?
            first_pass = false
            set_fiber_variables(fiber_vars)
            run_pending_steps(job_fibers, next_job_fibers, source_tasks, jobs_fiber_limit, trace, root_task, jobs_condition)

            while !source_tasks.empty? || @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
              while (task = (source_tasks.shift || (((job_fibers.size + next_job_fibers.size + source_tasks.size + next_source_tasks.size) < total_fiber_limit) && spawn_source_task(root_task, sources_condition, trace))))
                if task.alive?
                  root_task.yield
                  next_source_tasks << task
                else
                  task.wait # re-raise errors
                end
              end

              sources_condition.signal
              source_tasks.concat(next_source_tasks)
              next_source_tasks.clear
            end
            jobs_condition.signal

            if !@lazies_at_depth.empty?
              with_trace_query_lazy(trace_query_lazy) do
                run_next_pending_lazies(job_fibers, trace, root_task, jobs_condition)
                run_pending_steps(job_fibers, next_job_fibers, source_tasks, jobs_fiber_limit, trace, root_task, jobs_condition)
              end
            end
          end
        rescue StandardError => err
          raised_error = err
        end

        if raised_error
          raise raised_error
        end
        trace&.end_dataloader(self)

      rescue UncaughtThrowError => e
        throw e.tag, e.value
      end

      private

      def run_pending_steps(job_fibers, next_job_fibers, source_tasks, jobs_fiber_limit, trace, parent_task, condition)
        while (f = (job_fibers.shift || (((job_fibers.size + next_job_fibers.size + source_tasks.size) < jobs_fiber_limit) && spawn_job_task(trace, parent_task, condition))))
          if f.alive?
            parent_task.yield
            next_job_fibers << f
          else
            f.wait # re-raise errors
          end
        end
        job_fibers.concat(next_job_fibers)
        next_job_fibers.clear
      end

      def spawn_job_task(trace, parent_task, condition)
        if !@pending_jobs.empty?
          fiber_vars = get_fiber_variables
          parent_task.async do
            trace&.dataloader_spawn_execution_fiber(@pending_jobs)
            Fiber[:graphql_dataloader_next_tick] = condition
            set_fiber_variables(fiber_vars)
            while job = @pending_jobs.shift
              job.call
            end
            cleanup_fiber
            trace&.dataloader_fiber_exit
          end
        end
      end

      #### TODO DRY  Had to duplicate to remove spawn_job_fiber
      def run_next_pending_lazies(job_fibers, trace, parent_task, condition)
        smallest_depth = nil
        @lazies_at_depth.each_key do |depth_key|
          smallest_depth ||= depth_key
          if depth_key < smallest_depth
            smallest_depth = depth_key
          end
        end

        if smallest_depth
          lazies = @lazies_at_depth.delete(smallest_depth)
          if !lazies.empty?
            lazies.each_with_index do |l, idx|
              append_job { l.value }
            end
            job_fibers.unshift(spawn_job_task(trace, parent_task, condition))
          end
        end
      end

      def spawn_source_task(parent_task, condition, trace)
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
            trace&.dataloader_spawn_source_fiber(pending_sources)
            set_fiber_variables(fiber_vars)
            Fiber[:graphql_dataloader_next_tick] = condition
            pending_sources.each do |s|
              trace&.begin_dataloader_source(s)
              s.run_pending_keys
              trace&.end_dataloader_source(s)
            end
            nil
          rescue StandardError => err
            err
          ensure
            cleanup_fiber
            trace&.dataloader_fiber_exit
          end
        end
      end
    end
  end
end
