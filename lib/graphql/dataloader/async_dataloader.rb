# frozen_string_literal: true
require 'fiber'

module GraphQL
  class Dataloader
    class AsyncDataloader < Dataloader
      # This is mostly copied from the parent class, except for
      # a few random calls to `scheduler.run`
      def run
        prev_scheduler = Fiber.scheduler
        if !prev_scheduler.is_a?(Scheduler)
          # Create a new scheduler if there isn't one,
          # but if there's already one in action, don't bother
          scheduler = Scheduler.new
          Fiber.set_scheduler(scheduler)
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
        if !prev_scheduler.is_a?(Scheduler)
          # If this `run` is a top-level call, then put the old scheduler back
          # (It's probably `nil`)
          Fiber.set_scheduler(prev_scheduler)
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

      # From the Ruby source (https://github.com/ruby/ruby/blob/master/test/fiber/scheduler.rb)
      #
      # This is an example and simplified scheduler for test purposes.
      # It is not efficient for a large number of file descriptors as it uses IO.select().
      # Production Fiber schedulers should use epoll/kqueue/etc.

      require 'fiber'
      require 'socket'

      begin
        require 'io/nonblock'
      rescue LoadError
        # Ignore.
      end

      class Scheduler
        def initialize
          @readable = {}
          @writable = {}
          @waiting = {}

          @closed = false

          @lock = Mutex.new
          @blocking = 0
          @ready = []

          @urgent = IO.pipe
        end

        attr :readable
        attr :writable
        attr :waiting

        def next_timeout
          _fiber, timeout = @waiting.min_by{|key, value| value}

          if timeout
            offset = timeout - current_time

            if offset < 0
              return 0
            else
              return offset
            end
          end
        end

        def run
          # $stderr.puts [__method__, Fiber.current].inspect

          while @readable.any? or @writable.any? or @waiting.any? or @blocking.positive?
            # Can only handle file descriptors up to 1024...
            readable, writable = IO.select(@readable.keys + [@urgent.first], @writable.keys, [], next_timeout)

            # puts "readable: #{readable}" if readable&.any?
            # puts "writable: #{writable}" if writable&.any?

            selected = {}

            readable && readable.each do |io|
              if fiber = @readable.delete(io)
                selected[fiber] = IO::READABLE
              elsif io == @urgent.first
                @urgent.first.read_nonblock(1024)
              end
            end

            writable && writable.each do |io|
              if fiber = @writable.delete(io)
                selected[fiber] |= IO::WRITABLE
              end
            end

            selected.each do |fiber, events|
              fiber.resume(events)
            end

            if @waiting.any?
              time = current_time
              waiting, @waiting = @waiting, {}

              waiting.each do |fiber, timeout|
                if fiber.alive?
                  if timeout <= time
                    fiber.resume
                  else
                    @waiting[fiber] = timeout
                  end
                end
              end
            end

            if @ready.any?
              ready = nil

              @lock.synchronize do
                ready, @ready = @ready, []
              end

              ready.each do |fiber|
                fiber.resume
              end
            end
          end
        end

        def close
          # $stderr.puts [__method__, Fiber.current].inspect

          raise "Scheduler already closed!" if @closed

          self.run
        ensure
          @urgent.each(&:close)
          @urgent = nil

          @closed = true

          # We freeze to detect any unintended modifications after the scheduler is closed:
          self.freeze
        end

        def closed?
          @closed
        end

        def current_time
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        def timeout_after(duration, klass, message, &block)
          fiber = Fiber.current

          self.fiber do
            sleep(duration)

            if fiber && fiber.alive?
              fiber.raise(klass, message)
            end
          end

          begin
            yield(duration)
          ensure
            fiber = nil
          end
        end

        def process_wait(pid, flags)
          # $stderr.puts [__method__, pid, flags, Fiber.current].inspect

          # This is a very simple way to implement a non-blocking wait:
          Thread.new do
            Process::Status.wait(pid, flags)
          end.value
        end

        def io_wait(io, events, duration)
          # $stderr.puts [__method__, io, events, duration, Fiber.current].inspect

          unless (events & IO::READABLE).zero?
            @readable[io] = Fiber.current
          end

          unless (events & IO::WRITABLE).zero?
            @writable[io] = Fiber.current
          end

          Fiber.yield
        end

        # Used for Kernel#sleep and Mutex#sleep
        def kernel_sleep(duration = nil)
          # $stderr.puts [__method__, duration, Fiber.current].inspect

          self.block(:sleep, duration)

          return true
        end

        # Used when blocking on synchronization (Mutex#lock, Queue#pop, SizedQueue#push, ...)
        def block(blocker, timeout = nil)
          # $stderr.puts [__method__, blocker, timeout].inspect

          if timeout
            @waiting[Fiber.current] = current_time + timeout
            begin
              Fiber.yield
            ensure
              # Remove from @waiting in the case #unblock was called before the timeout expired:
              @waiting.delete(Fiber.current)
            end
          else
            @blocking += 1
            begin
              Fiber.yield
            ensure
              @blocking -= 1
            end
          end
        end

        # Used when synchronization wakes up a previously-blocked fiber (Mutex#unlock, Queue#push, ...).
        # This might be called from another thread.
        def unblock(blocker, fiber)
          # $stderr.puts [__method__, blocker, fiber].inspect
          # $stderr.puts blocker.backtrace.inspect
          # $stderr.puts fiber.backtrace.inspect

          @lock.synchronize do
            @ready << fiber
          end

          io = @urgent.last
          io.write_nonblock('.')
        end

        def fiber(&block)
          fiber = Fiber.new(blocking: false, &block)

          fiber.resume

          return fiber
        end
      end

    end
  end
end
