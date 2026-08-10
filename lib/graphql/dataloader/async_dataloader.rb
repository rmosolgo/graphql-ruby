# frozen_string_literal: true

module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      def self.use(...)
        install_graphql_methods
        super
      end

      def self.install_graphql_methods
        if !Async::Task.method_defined?(:cancel)
          Async::Task.alias_method(:cancel, :stop)
        end
        if !Async::Task.method_defined?(:graphql_async_dataloader_run)
          Async::Task.attr_accessor(:graphql_async_dataloader_run)
          Async::Task.attr_accessor(:graphql_async_dataloader_condition)
        end
      end

      def initialize(...)
        super
        create_pending_run
      end

      attr_reader :pending_sources # :nodoc:

      def create_pending_run
        jobs_fiber_limit, total_fiber_limit = calculate_fiber_limit
        @pending_run = Run.new(self, total_fiber_limit, jobs_fiber_limit)
      end

      def yield(source = Fiber[:__graphql_current_dataloader_source])
        task = Async::Task.current
        run = task.graphql_async_dataloader_run
        trace = run.trace
        trace&.dataloader_fiber_yield(source)
        if !run.push_task_message(:paused_task, task)
          task.stop
        end
        condition = task.graphql_async_dataloader_condition
        condition.wait
        if !run.push_task_message(:resumed_task, task)
          task.stop
        end
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
          @activity = nil
          @task_error = nil
          @expected_resumes = 0
          @mode = nil

          @snoozed_jobs_condition = Async::Condition.new
          @snoozed_sources_condition = Async::Condition.new
        end

        attr_accessor :trace, :root_task

        attr_reader :dataloader, :jobs, :lazies_at_depth, :jobs_fiber_limit,  :snoozed_jobs_condition, :snoozed_sources_condition

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

        # Push to the tasks_channel, tolerating a closed channel: on the error path, `run_queue`
        # closes the channel while sibling tasks can still run one more slice before
        # `root_task.cancel` reaches them. Record `:task_error` payloads so they aren't lost, and
        # return false so the caller can stop the task instead of raising `ClosedError` into user code.
        def push_task_message(msg, data)
          @tasks_channel.push([msg, data])
          true
        rescue Async::Queue::ClosedError
          if msg == :task_error
            @task_error ||= data
          end
          false
        end

        def wait_for_activity
          @activity.wait
        end

        def quiesced?
          @running_tasks.empty? && @tasks_channel.empty? && @expected_resumes == 0
        end

        def has_pending_work?
          @mode == :jobs ? @jobs.any? : @dataloader.pending_sources.any?(&:pending?) # rubocop:disable Development/NoneWithoutBlockCop
        end

        def has_bandwidth?
          @mode == :jobs ? jobs_bandwidth? : sources_bandwidth?
        end

        # Signalled tasks don't appear in any accounting until their first slice
        # pushes `:resumed_task`, so they have to be counted at signal time:
        def expect_resumes(count)
          @expected_resumes = count
        end

        def check_error!
          if (err = @task_error)
            @task_error = nil
            raise err
          end
        end

        def new_queues(mode)
          @mode = mode
          @tasks_channel = Async::Queue.new(parent: @root_task)
          @activity = Async::Condition.new
          @task_error = nil
          @expected_resumes = 0
          @running_tasks = []
          @tasks_channel_task = @root_task.async do |_t|
            while ((msg, data) = @tasks_channel.wait)
              case msg
              when :started_task
                @running_tasks.push(data)
                data.run
              when :resumed_task
                if @expected_resumes > 0
                  @expected_resumes -= 1
                end
                @running_tasks.push(data)
              when :finished_task, :paused_task
                @running_tasks.delete(data)
              when :task_error
                @task_error ||= data
              else
                raise ArgumentError, "Unknown tasks_channel action: #{msg.inspect}"
              end
              @activity.signal
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
        @pending_run || current_task_run || raise(GraphQL::Error, "No available Run to append to, GraphQL-Ruby bug")
      end

      # The current task's run, but only if it belongs to this dataloader. A different
      # dataloader may be running inside one of our tasks (or vice versa), e.g. a query
      # executed from a resolver or a subscription trigger; its run must not be reused.
      def current_task_run
        run = Async::Task.current?&.graphql_async_dataloader_run
        run if run&.dataloader.equal?(self)
      end

      def run_isolated
        previous_run = current_task_run
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
        run = @pending_run || current_task_run || raise(GraphQL::Error, "No available Run, GraphQL-Ruby internal bug")
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
        opened_queues = false

        if condition.waiting?
          opened_queues = true
          run.new_queues(mode)
          run.expect_resumes(condition.instance_variable_get(:@ready).num_waiting)
          condition.signal
        end

        loop do
          pending_work = (mode == :jobs) ? (!run.jobs.empty? && run.jobs_bandwidth? ? run.jobs : nil) : (drain_pending_sources)
          if pending_work
            if opened_queues == false
              opened_queues = true
              run.new_queues(mode)
            end
            num_tasks = mode == :sources ? run.current_sources_fiber_limit : 1
            if num_tasks > pending_work.size
              num_tasks = pending_work.size
            end
            spawn_tasks(run, mode, condition, pending_work, num_tasks)
          end

          if !opened_queues
            break
          end

          run.check_error!

          if run.quiesced?
            if !run.has_pending_work? || !run.has_bandwidth?
              break
            end
            # Quiesced, but more work appeared - loop around to drain it.
          else
            run.wait_for_activity
          end
        end
      ensure
        if opened_queues
          run.close_queues
        end
      end

      # Use a separate method for this so that the outer loop's reassignment of `pending_work`
      # doesn't affect already-running tasks which (would) close over that variable
      def spawn_tasks(run, mode, condition, pending_work, num_tasks)
        fiber_vars = get_fiber_variables
        trace = run.trace
        num_tasks.times do
          new_task = Async::Task.new(run.root_task) do |task|
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
            run.push_task_message(:task_error, err)
          else
            run.push_task_message(:finished_task, task)
          ensure
            cleanup_fiber
            trace&.dataloader_fiber_exit
          end
          run.push_task_message(:started_task, new_task)
        end
      end
    end
  end
end
