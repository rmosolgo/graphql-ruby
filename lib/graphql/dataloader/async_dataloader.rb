# frozen_string_literal: true
module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      attr_reader :pending_jobs, :source_cache
      def yield
        ::Async::Task.current.yield
        nil
      end

      class Queue
        def initialize(dataloader)
          @dataloader = dataloader
          @current_tasks = []
          @next_tasks = []
        end

        def run_once
          Async do
            while (task = @current_tasks.shift || get_new_task)
              if task.alive?
                @next_tasks << task
              end
            end
          end.wait
          @current_tasks.concat(@next_tasks)
          @next_tasks.clear
        end
      end

      class JobsQueue < Queue
        def initialize(*)
          super
          @first_pass = true
        end

        def run?
          if @first_pass
            @first_pass = false
            true
          else
            @current_tasks.any?
          end
        end

        def get_new_task
          if @dataloader.pending_jobs.any?
            fiber_vars = @dataloader.get_fiber_variables
            Async do
              @dataloader.set_fiber_variables(fiber_vars)
              while job = @dataloader.pending_jobs.shift
                job.call
              end
            end
          end
        end
      end

      class SourcesQueue < Queue
        def run?
          @current_tasks.any? || @dataloader.source_cache.each_value.any? { |group_sources| group_sources.each_value.any?(&:pending?) }
        end

        def get_new_task
          pending_sources = nil
          @dataloader.source_cache.each_value do |source_by_batch_params|
            source_by_batch_params.each_value do |source|
              if source.pending?
                pending_sources ||= []
                pending_sources << source
              end
            end
          end

          if pending_sources
            fiber_vars = @dataloader.get_fiber_variables
            Async do
              @dataloader.set_fiber_variables(fiber_vars)
              pending_sources.each(&:run_pending_keys)
            end
          end
        end
      end

      def run
        jobs_queue = JobsQueue.new(self)
        sources_queue = SourcesQueue.new(self)
        Sync do
          while jobs_queue.run?

            jobs_queue.run_once

            while sources_queue.run?
              sources_queue.run_once
            end
          end
        end
      rescue UncaughtThrowError => e
        throw e.tag, e.value
      end
    end
  end
end
