# frozen_string_literal: true

module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def yield(source = Fiber[:__graphql_current_dataloader_source])
        run = Fiber[:graphql_async_dataloader_run]
        trace = run.trace
        trace&.dataloader_fiber_yield(source)
        task = Async::Task.current
        run.finished_tasks.push(task)
        condition = Fiber[:graphql_async_dataloader_condition]
        condition.wait
        run.started_tasks.push(task)
        trace&.dataloader_fiber_resume(source)
        nil
      end

      class Run
        def initialize(root_task, trace, jobs_fiber_limit)
          @root_task = root_task
          @trace = trace
          @jobs_fiber_limit = jobs_fiber_limit
          @finished_tasks = Async::Queue.new
          @started_tasks = Async::Queue.new
          @snoozed_jobs_condition = Async::Condition.new
          @snoozed_sources_condition = Async::Condition.new
        end

        attr_reader :root_task, :trace, :jobs_fiber_limit, :finished_tasks, :started_tasks, :snoozed_jobs_condition, :snoozed_sources_condition

        def jobs_bandwidth?
          true # TODO implement fiber limit
        end

        def sources_bandwidth?
          true # TODO implement fiber limit
        end

        def close_queues
          @finished_tasks.close
          @started_tasks.close
        end

        def new_queues
          @finished_tasks = Async::Queue.new
          @started_tasks = Async::Queue.new
        end

        def running?
          @snoozed_jobs_condition.waiting? || @snoozed_sources_condition.waiting?
        end
      end

      def run(trace_query_lazy: nil)
        trace = Fiber[:__graphql_current_multiplex]&.current_trace
        jobs_fiber_limit, total_fiber_limit = calculate_fiber_limit
        first_pass = true
        trace&.begin_dataloader(self)
        fiber_vars = get_fiber_variables
        raised_error = nil
        Sync do |root_task|
          run = Run.new(root_task, trace, jobs_fiber_limit)
          set_fiber_variables(fiber_vars)

          while first_pass || run.running? || !@pending_jobs.empty?
            first_pass = false
            run_pending_steps(run)
            run_sources(run)


            if !@lazies_at_depth.empty?
              with_trace_query_lazy(trace_query_lazy) do
                run_next_pending_lazies(run)
                run_pending_steps(run)
              end
            end
          end
        rescue StandardError => err
          raised_error = err
          root_task.cancel
        end

        if raised_error
          raise raised_error
        end
        trace&.end_dataloader(self)
      rescue UncaughtThrowError => e
        throw e.tag, e.value
      end

      private

      def run_pending_steps(run)
        finished_all_tasks = nil
        completed_first_run = Async::Promise.new
        started_tasks = 0
        finished_tasks = 0
        run.new_queues

        counting_task = run.root_task.async do
          while _t = run.started_tasks.wait
            started_tasks += 1
            if (finished_tasks == started_tasks) && completed_first_run.resolved?
              finished_all_tasks.resolve(true)
            end
          end
        end

        waiting_task = run.root_task.async do
          while t_or_err = run.finished_tasks.wait
            if t_or_err.is_a?(StandardError)
              finished_all_tasks.reject(t_or_err)
            else
              finished_tasks += 1
              if finished_tasks == started_tasks
                finished_all_tasks.resolve(true)
              end
            end
          end
        end

        if (unsnoozed = run.snoozed_jobs_condition.waiting?)
          run.snoozed_jobs_condition.signal
        end

        while (!@pending_jobs.empty? && run.jobs_bandwidth?) || (unsnoozed)
          unsnoozed = false
          finished_all_tasks = Async::Promise.new
          spawn_job_task(run)

          if !completed_first_run.resolved?
            completed_first_run.resolve(true)
          end

          finished_all_tasks.wait
        end

        waiting_task.cancel
        counting_task.cancel
        run.close_queues
      end

      def spawn_job_task(run)
        if !@pending_jobs.empty?
          fiber_vars = get_fiber_variables
          run.root_task.async do |task|
            run.trace&.dataloader_spawn_execution_fiber(@pending_jobs)
            Fiber[:graphql_async_dataloader_run] = run
            Fiber[:graphql_async_dataloader_condition] = run.snoozed_jobs_condition
            set_fiber_variables(fiber_vars)
            run.started_tasks.push(task)
            while job = @pending_jobs.shift
              job.call
            end
          ensure
            cleanup_fiber
            run.finished_tasks.push($! || task)
            run.trace&.dataloader_fiber_exit
          end
        end
      end

      def run_sources(run)
        started_tasks = 0
        finished_tasks = 0
        run.new_queues
        completed_first_run = Async::Promise.new
        finished_all_tasks = Async::Promise.new

        counting_task = run.root_task.async do
          completed_first_run.wait
          while _t = run.started_tasks.wait
            started_tasks += 1
            if finished_tasks == started_tasks
              finished_all_tasks.resolve(true)
            end
          end
        end

        waiting_task = run.root_task.async do
          completed_first_run.wait
          while t_or_err = run.finished_tasks.wait
            if t_or_err.is_a?(StandardError)
              finished_all_tasks.reject(t_or_err)
            else
              finished_tasks += 1
              if finished_tasks == started_tasks
                finished_all_tasks.resolve(true)
              end
            end
          end
        end

        if (unsnoozed = run.snoozed_sources_condition.waiting?)
          run.snoozed_sources_condition.signal
        end

        while unsnoozed || (run.sources_bandwidth? && @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) })
          unsnoozed = false
          spawn_source_task(run)

          if !completed_first_run.resolved?
            completed_first_run.resolve(true)
          end

          finished_all_tasks.wait
        end
      ensure
        waiting_task.cancel
        counting_task.cancel
        run.close_queues
      end

      #### TODO DRY  Had to duplicate to remove spawn_job_fiber
      def run_next_pending_lazies(run)
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
            spawn_job_task(run) # Todo what was the last `true` condition?
          end
        end
      end

      def spawn_source_task(run)
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
          trace = run.trace
          pending_sources.each do |source|
            run.root_task.async do |task|
              Fiber[:graphql_async_dataloader_run] = run
              Fiber[:graphql_async_dataloader_condition] = run.snoozed_sources_condition
              trace&.dataloader_spawn_source_fiber(pending_sources)
              set_fiber_variables(fiber_vars)
              run.started_tasks.push(task)
              trace&.begin_dataloader_source(source)
              source.run_pending_keys
              trace&.end_dataloader_source(source)
              nil
            ensure
              run.finished_tasks.push($! || task)
              cleanup_fiber
              trace&.dataloader_fiber_exit
            end
          end
        end
      end
    end
  end
end
