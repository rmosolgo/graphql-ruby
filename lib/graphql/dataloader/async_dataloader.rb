# frozen_string_literal: true

module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def yield(source = Fiber[:__graphql_current_dataloader_source])
        run = Fiber[:__graphql_async_dataloader_run]
        trace = run.trace
        trace&.dataloader_fiber_yield(source)
        task = Async::Task.current
        run.finished_tasks.push(task)
        condition = Fiber[:__graphql_async_dataloader_condition]
        condition.wait
        run.started_tasks.push(task)
        trace&.dataloader_fiber_resume(source)
        nil
      end

      class Run
        def initialize(root_task, trace, total_fiber_limit, jobs_fiber_limit)
          @root_task = root_task
          @trace = trace
          @total_fiber_limit = total_fiber_limit
          @jobs_fiber_limit = jobs_fiber_limit

          @finished_tasks = nil
          @started_tasks = nil
          @started_count_task = nil
          @finished_count_task = nil
          @finished_all_tasks = nil
          @finished_first_pass = nil

          @snoozed_jobs_condition = Async::Condition.new
          @snoozed_sources_condition = Async::Condition.new
        end

        attr_reader :root_task, :trace, :jobs_fiber_limit, :total_fiber_limit, :finished_tasks, :started_tasks, :snoozed_jobs_condition, :snoozed_sources_condition


        def jobs_bandwidth?
          running_count < jobs_fiber_limit
        end

        def allowed_sources_tasks
          within_limit = total_fiber_limit - running_count
          if within_limit < 1
            1
          else
            within_limit
          end
        end

        def close_queues
          @finished_tasks.close
          @finished_count_task.cancel

          @started_tasks.close
          @started_count_task.cancel
        end

        def running_count
          @snoozed_jobs_condition.instance_variable_get(:@ready).num_waiting +
            @snoozed_sources_condition.instance_variable_get(:@ready).num_waiting +
            @started_count +
            @started_tasks.size -
            @finished_count
        end

        def wait_for_queues
          if !@finished_first_pass.resolved?
            @finished_first_pass.resolve(true)
          end

          @finished_all_tasks.wait
          @finished_all_tasks = Async::Promise.new
        end

        def new_queues
          @finished_tasks = Async::Queue.new
          @finished_count = 0
          @started_tasks = Async::Queue.new
          @started_count = 0
          @finished_first_pass = Async::Promise.new
          @finished_all_tasks = Async::Promise.new

          @started_count_task = @root_task.async do
            @finished_first_pass.wait
            while _t = @started_tasks.wait
              @started_count += 1
              if @finished_count == @started_count
                @finished_all_tasks.resolve(true)
              end
            end
          end

          @finished_count_task = @root_task.async do
            while t_or_err = @finished_tasks.wait
              if t_or_err.is_a?(StandardError)
                @finished_all_tasks.reject(t_or_err)
              else
                @finished_count +=1
                if @finished_count == @started_count
                  @finished_all_tasks.resolve(true)
                end
              end
            end
          end
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
          run = Run.new(root_task, trace, total_fiber_limit, jobs_fiber_limit)
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
        run.new_queues

        if (unsnoozed = run.snoozed_jobs_condition.waiting?)
          run.snoozed_jobs_condition.signal
        end

        while (!@pending_jobs.empty? && (has_limit = run.jobs_bandwidth?)) || (unsnoozed)
          unsnoozed = false
          if has_limit
            spawn_job_task(run)
          end
          run.wait_for_queues
        end
      ensure
        run.close_queues
      end

      def spawn_job_task(run)
        if !@pending_jobs.empty?
          fiber_vars = get_fiber_variables
          run.root_task.async do |task|
            run.trace&.dataloader_spawn_execution_fiber(@pending_jobs)
            Fiber[:__graphql_async_dataloader_run] = run
            Fiber[:__graphql_async_dataloader_condition] = run.snoozed_jobs_condition
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
        run.new_queues

        if (unsnoozed = run.snoozed_sources_condition.waiting?)
          run.snoozed_sources_condition.signal
        end

        allowed_tasks = run.allowed_sources_tasks
        while (has_pending = @source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) } ) || unsnoozed
          unsnoozed = false
          if has_pending
            spawn_source_task(run, allowed_tasks)
          end
          run.wait_for_queues
        end
      ensure
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

      def spawn_source_task(run, num_tasks)
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
          if num_tasks == Float::INFINITY
            num_tasks = pending_sources.size
          end
          fiber_vars = get_fiber_variables
          trace = run.trace
          num_tasks.times do
            run.root_task.async do |task|
              Fiber[:__graphql_async_dataloader_run] = run
              Fiber[:__graphql_async_dataloader_condition] = run.snoozed_sources_condition
              trace&.dataloader_spawn_source_fiber(pending_sources)
              set_fiber_variables(fiber_vars)
              run.started_tasks.push(task)
              while (source = pending_sources.shift)
                trace&.begin_dataloader_source(source)
                source.run_pending_keys
                trace&.end_dataloader_source(source)
              end
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
