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

      # @api private
      attr_reader :pending_sources

      def create_pending_run
        jobs_fiber_limit, total_fiber_limit = calculate_fiber_limit
        @pending_run = Run.new(self, total_fiber_limit, jobs_fiber_limit)
      end

      def yield(source = Fiber[:__graphql_current_dataloader_source])
        task = Async::Task.current
        run = task.graphql_async_dataloader_run
        trace = run.trace
        trace&.dataloader_fiber_yield(source)
        run.tasks_channel.push([:paused_task, task])
        condition = task.graphql_async_dataloader_condition
        condition.wait
        run.tasks_channel.push([:resumed_task, task])
        trace&.dataloader_fiber_resume(source)
        nil
      end

      class Run
        def initialize(dataloader, total_fiber_limit, jobs_fiber_limit)
          @dataloader = dataloader
          @root_task = nil
          @trace = nil
          @jobs = []

          @total_fiber_limit = total_fiber_limit
          @jobs_fiber_limit = jobs_fiber_limit
          @lazies_at_depth = Hash.new { |h, k| h[k] = [] }

          @running_tasks = nil
          @tasks_channel = nil
          @tasks_channel_task = nil
          @finished_all_tasks = nil

          @snoozed_jobs_condition = Async::Condition.new
          @snoozed_sources_condition = Async::Condition.new
        end

        attr_accessor :trace, :root_task

        attr_reader :jobs, :lazies_at_depth,  :snoozed_jobs_condition, :snoozed_sources_condition, :tasks_channel

        def jobs_bandwidth?
          running_count < @jobs_fiber_limit
        end

        def sources_bandwidth?
          running_count < current_sources_fiber_limit
        end

        def close_queues
          @tasks_channel.close
          @tasks_channel_task.cancel
        end

        def wait_for_queues
          @finished_all_tasks.wait
          @finished_all_tasks = Async::Promise.new
        end

        def wait_for_no_running_tasks
          @no_running_tasks.wait
          @no_running_tasks = Async::Promise.new
        end

        def new_queues(mode)
          @tasks_channel = Async::Queue.new(parent: @root_task)
          @no_running_tasks = Async::Promise.new
          @finished_all_tasks = Async::Promise.new
          @running_tasks = []
          @tasks_channel_task = @root_task.async do |_t|
            while ((msg, data) = @tasks_channel.wait)
              case msg
              when :started_task
                @running_tasks.push(data)
                data.run
              when :resumed_task
                @running_tasks.push(data)
              when :finished_task, :paused_task
                @running_tasks.delete(data)
                has_pending_work = mode == :jobs ? @jobs.any? : @dataloader.pending_sources.any?(&:pending?) # rubocop:disable Development/NoneWithoutBlockCop
                if @running_tasks.empty?
                  @no_running_tasks.resolve(true)
                  has_bandwidth = mode == :jobs ? jobs_bandwidth? : sources_bandwidth?
                  if (!has_pending_work) || (!has_bandwidth)
                    @finished_all_tasks.resolve(true)
                  end
                end
              when :task_error
                @no_running_tasks.resolve(true)
                @finished_all_tasks.reject(data)
              else
                raise ArgumentError, "Unknown tasks_channel action: #{msg.inspect}"
              end
            end
          end
        end

        def running?
          @snoozed_jobs_condition.waiting? || @snoozed_sources_condition.waiting?
        end

        def current_sources_fiber_limit
          within_limit = @total_fiber_limit - running_count
          if within_limit < 1
            1
          else
            within_limit
          end
        end

        private

        def running_count
          @snoozed_jobs_condition.instance_variable_get(:@ready).num_waiting +
            @snoozed_sources_condition.instance_variable_get(:@ready).num_waiting +
            (@running_tasks&.size || 0)
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
              run_queue(run, run.snoozed_jobs_condition, :jobs)
              run_queue(run, run.snoozed_sources_condition, :sources)

              if !run.lazies_at_depth.empty?
                with_trace_query_lazy(trace_query_lazy) do
                  if enqueue_next_pending_lazies(run.lazies_at_depth)
                    run_queue(run, run.snoozed_jobs_condition, :jobs)
                  end
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

      def run_queue(run, condition, mode)
        should_wait_for_all_tasks = false

        if (unsnoozed = condition.waiting?)
          should_wait_for_all_tasks = true
          run.new_queues(mode)
          condition.signal
        end

        while (loop_pending_work = (mode == :jobs) ? (!run.jobs.empty? && run.jobs_bandwidth? ? run.jobs : nil) : (drain_pending_sources)) || unsnoozed
          unsnoozed = false
          if loop_pending_work
            if should_wait_for_all_tasks == false
              should_wait_for_all_tasks = true
              run.new_queues(mode)
            end

            num_tasks = if mode == :sources
              n = run.current_sources_fiber_limit
              if n == Float::INFINITY
                loop_pending_work.size
              else
                n
              end
            else
              1
            end

            fiber_vars = get_fiber_variables
            trace = run.trace

            num_tasks.times do
              new_task = Async::Task.new(run.root_task) do |task|
                pending_work = loop_pending_work # avoid overrides from assignment in `while`
                task.graphql_async_dataloader_run = run
                task.graphql_async_dataloader_condition = condition
                set_fiber_variables(fiber_vars)
                case mode
                when :jobs
                  trace&.dataloader_spawn_execution_fiber(pending_work)
                  while job = pending_work.shift
                    job.call
                  end
                when :sources
                  trace&.dataloader_spawn_source_fiber(pending_work)
                  while (source = pending_work.shift)
                    Fiber[:__graphql_current_dataloader_source] = source
                    trace&.begin_dataloader_source(source)
                    source.run_pending_keys
                    trace&.end_dataloader_source(source)
                  end
                else
                  raise ArgumentError, "Unknown mode: #{mode.inspect}"
                end
                nil
              rescue StandardError => err
                run.tasks_channel.push([:task_error, err])
              else
                run.tasks_channel.push([:finished_task, task])
              ensure
                cleanup_fiber
                trace&.dataloader_fiber_exit
              end
              run.tasks_channel.push([:started_task, new_task])
            end
          end

          run.wait_for_no_running_tasks
        end

        if should_wait_for_all_tasks
          run.wait_for_queues
        end
      ensure
        if should_wait_for_all_tasks
          run.close_queues
        end
      end
    end
  end
end
