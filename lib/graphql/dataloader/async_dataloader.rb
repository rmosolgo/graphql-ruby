# frozen_string_literal: true


def ts_puts(str)
    puts "[#{Time.now.to_f.to_s.ljust(18)} | #{Async::Task.current.object_id} | #{Fiber.current.object_id}] #{str}"
end
module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def yield(source = Fiber[:__graphql_current_dataloader_source])
        trace = Fiber[:__graphql_current_multiplex]&.current_trace
        trace&.dataloader_fiber_yield(source)
        task = Async::Task.current
        working_jobs = Fiber[:graphql_dataloader_working_jobs]
        waiting_jobs = Fiber[:graphql_dataloader_waiting_jobs]
        working_jobs.delete(task)
        waiting_jobs << task
        ts_puts "Snoozing #{working_jobs.size} / #{@pending_jobs.size}"
        if working_jobs.empty?
          ts_puts "Yield signalling manager condition"
          # TODO This won't properly wait for next_tick
          Fiber[:graphql_dataloader_manager].signal
        end
        ts_puts "Waiting for jobs condition (#{Fiber[:graphql_dataloader_next_tick].object_id})"
        Fiber[:graphql_dataloader_next_tick].wait
        ts_puts "Resuming"
        trace&.dataloader_fiber_resume(source)
        waiting_jobs.delete(task)
        working_jobs << task
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
        parent_condition = Async::Condition.new
        sources_condition = Async::Condition.new
        jobs_condition = Async::Condition.new
        trace&.begin_dataloader(self)
        fiber_vars = get_fiber_variables
        raised_error = nil
        loops = 0
        Sync do |root_task|
          while first_pass || !job_fibers.empty? || !next_job_fibers.empty?
            ts_puts "WHILE #{@pending_jobs.size} / #{job_fibers.map(&:object_id)} / #{next_job_fibers.map(&:object_id)} / #{source_tasks.map(&:object_id)} / #{next_source_tasks.map(&:object_id)}"
            loops += 1
            first_pass = false
            set_fiber_variables(fiber_vars)
            run_pending_steps(job_fibers, next_job_fibers, source_tasks, jobs_fiber_limit, trace, root_task, jobs_condition, parent_condition)

            if !source_tasks.empty? || @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
              while ((job_fibers.size + next_job_fibers.size + source_tasks.size + next_source_tasks.size) < total_fiber_limit) &&
                  @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
                ts_puts "source while"
                spawn_source_task(root_task, sources_condition, trace, source_tasks, next_source_tasks, parent_condition)
              end

              if source_tasks.any?
                ts_puts "WAIT for manager"
                parent_condition.wait
              end
              ts_puts "SIGNAL to sources condition"
              sources_condition.signal
              ts_puts "END Sources run"
            end
            if jobs_condition.waiting?
              ts_puts "SIGNAL to jobs condition (#{jobs_condition.object_id}, #{jobs_condition.waiting?})"
              jobs_condition.signal
              ts_puts "WAIT for parent_condition in main loop"
              possible_error = parent_condition.wait
              if possible_error
                raise possible_error
              end
            end

            if !@lazies_at_depth.empty?
              with_trace_query_lazy(trace_query_lazy) do
                run_next_pending_lazies(job_fibers, trace, root_task, jobs_condition, next_job_fibers, parent_condition)
                run_pending_steps(job_fibers, next_job_fibers, source_tasks, jobs_fiber_limit, trace, root_task, jobs_condition, parent_condition)
              end
            end

            ts_puts [loops:].inspect
            if loops > 10
              root_task.cancel
            end
          end
          ts_puts "END Sync { ... }"
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

      def run_pending_steps(job_fibers, next_job_fibers, source_tasks, jobs_fiber_limit, trace, parent_task, condition, parent_condition)
        ts_puts "Run pending steps task"
        # while (f = (job_fibers.shift || (((job_fibers.size + next_job_fibers.size + source_tasks.size) < jobs_fiber_limit) && spawn_job_task(trace, parent_task, condition, job_fibers, next_job_fibers))))
        while ((job_fibers.size + next_job_fibers.size + source_tasks.size) < jobs_fiber_limit) && !@pending_jobs.empty?
          ts_puts "WHILE Spawning job tasks (#{@pending_jobs.size} jobs)"
          spawn_job_task(trace, parent_task, condition, job_fibers, next_job_fibers, parent_condition)
        end
        if !job_fibers.empty?
          ts_puts "Waiting for manager condition"
          possible_err = parent_condition.wait
          ts_puts "possible_err: #{possible_err}"
          if possible_err
            raise possible_err
          end
        end
        ts_puts "Finished run_pending_steps task"
      end

      def spawn_job_task(trace, parent_task, condition, job_fibers, next_job_fibers, parent_condition, prepend = false )
        if !@pending_jobs.empty?
          fiber_vars = get_fiber_variables
          new_task = parent_task.async do |task|
            ts_puts "New jobs task"
            trace&.dataloader_spawn_execution_fiber(@pending_jobs)
            Fiber[:graphql_dataloader_working_jobs] = job_fibers
            Fiber[:graphql_dataloader_waiting_jobs] = next_job_fibers
            Fiber[:graphql_dataloader_next_tick] = condition
            Fiber[:graphql_dataloader_manager] = parent_condition
            set_fiber_variables(fiber_vars)
            if prepend
              job_fibers.unshift(task)
            else
              job_fibers.push(task)
            end
            while job = @pending_jobs.shift
              ts_puts "Dequeued #{job.class} ##{job.object_id}"
              job.call
              ts_puts "Finished job #{job.class}  ##{job.object_id}"
            end
          ensure
            cleanup_fiber
            ts_puts "END JOBS TASK, #{$!}"
            job_fibers.delete(task)
            if job_fibers.empty? && @pending_jobs.empty?
              ts_puts "Signal parent condition from spawn_job_task"
              parent_condition.signal($!)
            end
            trace&.dataloader_fiber_exit
          end
          if !new_task.alive?
            new_task.wait # raise the error
          end
        end
      end

      #### TODO DRY  Had to duplicate to remove spawn_job_fiber
      def run_next_pending_lazies(job_fibers, trace, parent_task, condition, next_job_fibers, parent_condition)
        ts_puts "run_next_pending_lazies"
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
            spawn_job_task(trace, parent_task, condition, job_fibers, next_job_fibers, parent_condition, true)
          end
        end
      end

      def spawn_source_task(parent_task, condition, trace, source_tasks, next_source_tasks, parent_condition)
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
          new_task = parent_task.async do |task|
            ts_puts "Starting sources task"
            source_tasks << task
            Fiber[:graphql_dataloader_working_jobs] = source_tasks
            Fiber[:graphql_dataloader_waiting_jobs] = next_source_tasks
            trace&.dataloader_spawn_source_fiber(pending_sources)
            set_fiber_variables(fiber_vars)
            Fiber[:graphql_dataloader_next_tick] = condition
            Fiber[:graphql_dataloader_manager] = parent_condition
            pending_sources.each do |s|
              ts_puts "Running #{s.class}"
              trace&.begin_dataloader_source(s)
              s.run_pending_keys
              trace&.end_dataloader_source(s)
              ts_puts "Finished #{s.class}"
            end
            nil
          ensure
            ts_puts "Ending sources task"
            source_tasks.delete(task)
            if source_tasks.empty?
              ts_puts "Signaling parent condition from spawn_source_task"
              parent_condition.signal
            end
            cleanup_fiber
            trace&.dataloader_fiber_exit
          end
          if !new_task.alive?
            new_task.wait # raise the error
          end
        end
      end
    end
  end
end
