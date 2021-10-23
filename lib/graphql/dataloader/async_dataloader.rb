# frozen_string_literal: true
require 'fiber'

module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      # This is mostly copied from the parent class, except for
      # a few random calls to `Fiber.scheduler.run`
      def run
        if !Fiber.scheduler
          raise "AsyncDataloader requires `Fiber.scheduler`, assign one with `Fiber.set_scheduler(...)` before executing GraphQL."
        end

        next_fibers = []
        pending_fibers = []
        first_pass = true
        while first_pass || (f = pending_fibers.shift)
          if first_pass
            first_pass = false
          else
            resume(f)
            if f.alive?
              next_fibers << f
            end
          end

          while @pending_jobs.any?
            f = spawn_fiber {
              while (job = @pending_jobs.shift)
                job.call
              end
            }
            resume(f)
            if f.alive?
              next_fibers << f
            end
          end

          if pending_fibers.empty?
            source_fiber_stack = if (first_source_fiber = create_source_fiber)
              [first_source_fiber]
            else
              nil
            end

            while source_fiber_stack && source_fiber_stack.any?
              next_source_fiber_stack = []
              while (outer_source_fiber = source_fiber_stack.pop)
                resume(outer_source_fiber)
                if outer_source_fiber.alive?
                  next_source_fiber_stack << outer_source_fiber
                end
                next_source_fiber = create_source_fiber
                if next_source_fiber
                  source_fiber_stack << next_source_fiber
                end
              end
              Fiber.scheduler.run
              next_source_fiber_stack.select!(&:alive?)
              source_fiber_stack.concat(next_source_fiber_stack)
              next_source_fiber_stack.clear
            end
            Fiber.scheduler.run
            # Any fibers who yielded on I/O will still be in the list,
            # but they'll have been finished by `.run` above
            pending_fibers.select!(&:alive?)
            next_fibers.select!(&:alive?)

            pending_fibers.concat(next_fibers)
            next_fibers.clear
          end
        end


        if @pending_jobs.any?
          raise "Invariant: #{@pending_jobs.size} pending jobs"
        elsif pending_fibers.any?
          raise "Invariant: #{pending_fibers.size} pending fibers: #{pending_fibers}"
        elsif next_fibers.any?
          raise "Invariant: #{next_fibers.size} next fibers"
        end
        nil
      end

      # Copied from the default, except it passes `blocking: false`
      def spawn_fiber
        fiber_locals = {}

        Thread.current.keys.each do |fiber_var_key|
          fiber_locals[fiber_var_key] = Thread.current[fiber_var_key]
        end

        # This is _like_ `Fiber.schedule` except that `Fiber.schedule` runs the fiber immediately,
        # calling `.resume` on it after initializing it.
        # But I've got `resume` worked into the flow above. Maybe this could be refactored
        # to use the other expected API, but I'm not sure it matters
        Fiber.new(blocking: false) do
          fiber_locals.each { |k, v| Thread.current[k] = v }
          yield
        end
      end
    end
  end
end
