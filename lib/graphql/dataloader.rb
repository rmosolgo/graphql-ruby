# frozen_string_literal: true

require "graphql/dataloader/source"

module GraphQL
  class Dataloader
    def initialize(context)
      @context = context
      @loader_cache = {}
      @waiting_fibers = []
    end

    # Each query in a multiplex appends their first fiber.
    # Then when they're all done, the fibers are all run in the same pool.
    def append(fiber)
      # puts "[Fiber:#{fiber.object_id}] appended"
      @waiting_fibers << fiber
    end

    # Run all Fibers until they're all done
    # @return [void]
    def run
      # Start executing Fibers. This will run until all the Fibers are done.
      already_run_fibers = []
      while (current_fiber = @waiting_fibers.pop)
        # puts "[Fiber:#{current_fiber.object_id}] resume"
        # Run this fiber until its next yield.
        # If the Fiber yields, it will return an object for continuing excecution.
        # If it doesn't yield, it will return `nil`
        progress_f = current_fiber.resume
        # puts "[Fiber:#{current_fiber.object_id}] (#{current_fiber.alive? ? "Alive" : "Dead"}) progress: #{progress_f.class}:#{progress_f.object_id}"

        # This fiber yielded; there's more to do here.
        # (If `#alive?` is false, then the fiber concluded without yielding.)
        if current_fiber.alive?
          # puts "[Fiber:#{current_fiber.object_id}] alive, queuing"
          already_run_fibers << current_fiber
        end

        # if there's a _new_ fiber from this selection,
        # queue it up first.
        if progress_f
          # puts "[Fiber:#{progress_f.object_id}] creating from progress"
          @waiting_fibers << progress_f
        end

        if @waiting_fibers.empty?
          @context[:loader].run_pending_keys
          @waiting_fibers.concat(already_run_fibers)
          already_run_fibers.clear
        end
      end
      nil
    end

    class << self
      def self.current
        Thread.current[:graphql_dataloader]
      end

      def self.current=(dl)
        Thread.current[:graphql_dataloader] = dl
      end
    end
  end
end
