# frozen_string_literal: true

module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def self.use(...)
        if !Async::Task.method_defined?(:cancel)
          Async::Task.alias_method(:cancel, :stop)
        end
        if !Async::Task.method_defined?(:graphql_async_dataloader_run)
          Async::Task.attr_accessor(:graphql_async_dataloader_run)
          Async::Task.attr_accessor(:graphql_async_dataloader_condition)
        end
        super
      end

      def initialize(...)
        super
        create_pending_run
      end

      def create_pending_run
        jobs_fiber_limit, total_fiber_limit = calculate_fiber_limit
        @pending_run = Run.new(total_fiber_limit, jobs_fiber_limit)
      end

      def yield(source = Fiber[:__graphql_current_dataloader_source])
        task = Async::Task.current
        run = task.graphql_async_dataloader_run
        trace = run.trace
        trace&.dataloader_fiber_yield(source)
        run.finished_tasks.push(task)
        condition = task.graphql_async_dataloader_condition
        condition.wait
        run.started_tasks.push(task)
        trace&.dataloader_fiber_resume(source)
        nil
      end

      class Run
        def initialize(total_fiber_limit, jobs_fiber_limit)
          @root_task = nil
          @trace = nil
          @jobs = []

          @total_fiber_limit = total_fiber_limit
          @jobs_fiber_limit = jobs_fiber_limit
          @lazies_at_depth = Hash.new { |h, k| h[k] = [] }

          @finished_tasks = nil
          @started_tasks = nil
          @started_count_task = nil
          @finished_count_task = nil
          @finished_all_tasks = nil
          @finished_first_pass = nil

          @snoozed_jobs_condition = Async::Condition.new
          @snoozed_sources_condition = Async::Condition.new
        end

        attr_accessor :trace, :root_task

        attr_reader :jobs, :lazies_at_depth, :jobs_fiber_limit, :total_fiber_limit, :finished_tasks, :started_tasks, :snoozed_jobs_condition, :snoozed_sources_condition

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

        def mark_finished(t_or_err)
          if !@finished_tasks.closed? # This can be closed if a previous error caused the parent task to cancel
            @finished_tasks.push(t_or_err)
          end
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

          @started_count_task = @root_task.async do |task|
            @finished_first_pass.wait
            while t_or_err = @started_tasks.wait
              if t_or_err.is_a?(StandardError)
                @finished_all_tasks.reject(t_or_err)
              else
                @started_count += 1
                if t_or_err.status == :initialized # could also be resumed after waiting
                  t_or_err.run
                end
              end
            end
          end

          @finished_count_task = @root_task.async do |task|
            while t_or_err = @finished_tasks.wait
              if t_or_err.is_a?(StandardError)
                @finished_all_tasks.reject(t_or_err)
              else
                @finished_count += 1
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

      def append_job(callable = nil, &block)
        active_run.jobs.push(callable || block)
        nil
      end

      def lazy_at_depth(depth, lazy)
        active_run.lazies_at_depth[depth] << lazy
      end

      def active_run
        @pending_run || Async::Task.current?&.graphql_async_dataloader_run || raise(GraphQL::Error, "No available Run to append to, GraphQL-Ruby bug")
      end

      def run_isolated
        previous_run = Async::Task.current?&.graphql_async_dataloader_run
        prev_pending_keys = {}
        # Clear pending loads but keep already-cached records
        # in case they are useful to the given block.
        @source_cache.each do |source_class, batched_sources|
          batched_sources.each do |batch_args, batched_source_instance|
            if batched_source_instance.pending?
              prev_pending_keys[batched_source_instance] = batched_source_instance.pending.dup
              batched_source_instance.pending.clear
            end
          end
        end

        res = nil
        create_pending_run
        @pending_run.jobs << -> { res = yield }
        run
        res
      ensure
        if previous_run
          Async::Task.current.graphql_async_dataloader_run = previous_run
          # clear the one created in #run:
          @pending_run = nil
        end
        prev_pending_keys.each do |source_instance, pending|
          pending.each do |key, value|
            next if source_instance.results.key?(key)

            queue_pending_source(source_instance) if source_instance.pending.empty?
            source_instance.pending[key] = value
          end
        end
      end

      def run(trace_query_lazy: nil)
        trace = Fiber[:__graphql_current_multiplex]&.current_trace
        run = @pending_run || Async::Task.current?&.graphql_async_dataloader_run || raise(GraphQL::Error, "No available Run, GraphQL-Ruby internal bug")
        @pending_run = nil
        run.trace = trace
        first_pass = true
        trace&.begin_dataloader(self)
        fiber_vars = get_fiber_variables
        raised_error = nil
        jobs = run.jobs
        Sync do |_maybe_new_task|
          # Make sure there's a new task instance to hold `.graphql_...` state:
          task = Async::Task.new do |root_task|
            run.root_task = root_task
            root_task.graphql_async_dataloader_run = run
            set_fiber_variables(fiber_vars)

            while first_pass || run.running? || !jobs.empty?
              first_pass = false
              run_pending_steps(run)
              run_sources(run)

              if !run.lazies_at_depth.empty?
                with_trace_query_lazy(trace_query_lazy) do
                  run_next_pending_lazies(run.lazies_at_depth) { run_lazy_jobs(run) }
                  run_pending_steps(run)
                end
              end
            end
          rescue StandardError => err
            raised_error = err
            root_task.cancel
          end

          task.run
          task.wait
        end
        create_pending_run
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
        pending_jobs = run.jobs
        while (!pending_jobs.empty? && (has_limit = run.jobs_bandwidth?)) || (unsnoozed)
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
        pending_jobs = run.jobs
        if !pending_jobs.empty?
          fiber_vars = get_fiber_variables
          new_task = Async::Task.new(run.root_task) do |task|
            run.trace&.dataloader_spawn_execution_fiber(pending_jobs)
            task.graphql_async_dataloader_run = run
            task.graphql_async_dataloader_condition = run.snoozed_jobs_condition
            set_fiber_variables(fiber_vars)
            while job = pending_jobs.shift
              job.call
            end
          rescue StandardError => err
            run.mark_finished(err)
          else
            run.mark_finished(task)
          ensure
            cleanup_fiber
            run.trace&.dataloader_fiber_exit
          end
          run.started_tasks.push(new_task)
          new_task
        end
      end

      def run_sources(run)
        run.new_queues

        if (unsnoozed = run.snoozed_sources_condition.waiting?)
          run.snoozed_sources_condition.signal
        end

        allowed_tasks = run.allowed_sources_tasks
        while (pending_sources = drain_pending_sources) || unsnoozed
          unsnoozed = false
          spawn_source_task(run, allowed_tasks, pending_sources) if pending_sources
          run.wait_for_queues
        end
      ensure
        run.close_queues
      end

      def run_lazy_jobs(run)
        run.new_queues
        spawn_job_task(run)
        run.wait_for_queues
      ensure
        run.close_queues
      end

      def spawn_source_task(run, num_tasks, pending_sources)
        if num_tasks == Float::INFINITY
          num_tasks = pending_sources.size
        end

        fiber_vars = get_fiber_variables
        trace = run.trace
        num_tasks.times do
          new_task = Async::Task.new(run.root_task) do |task|
            task.graphql_async_dataloader_run = run
            task.graphql_async_dataloader_condition = run.snoozed_sources_condition
            trace&.dataloader_spawn_source_fiber(pending_sources)
            set_fiber_variables(fiber_vars)
            while (source = pending_sources.shift)
              trace&.begin_dataloader_source(source)
              source.run_pending_keys
              trace&.end_dataloader_source(source)
            end
            nil
          rescue StandardError => err
            run.mark_finished(err)
          else
            run.mark_finished(task)
          ensure
            cleanup_fiber
            trace&.dataloader_fiber_exit
          end
          run.started_tasks.push(new_task)
          new_task
        end
      end
    end
  end
end
