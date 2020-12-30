# frozen_string_literal: true

require "graphql/dataloader/source"

module GraphQL
  class Dataloader
    # The default implementation of dataloading -- all no-ops.
    #
    # The Dataloader interface isn't public, but it enables
    # simple internal code while adding the option to add Dataloader.
    class NullDataloader < Dataloader
      # @param prepared [Proc]
      def enqueue(prepared = nil, &block)
        (prepared || block).call
      end

      # @return [Proc]
      def prepare(&block)
        block
      end

      def run; end
      def yield; end
    end

    def self.use(schema)
      schema.dataloader_class = self
    end

    def initialize(context)
      @context = context
      @source_cache = {}
      @waiting_fibers = []
    end

    # @return [Hash] the {Multiplex} context
    attr_reader :context

    # Add some work to this dataloader to be scheduled later.
    # @param prepared [Fiber] some work prepared with {prepare}
    # @param block Some work to enqueue
    # @return [void]
    def enqueue(prepared = nil, &block)
      prepared ||= Fiber.new {
        begin
          yield
        rescue StandardError => err
          err
        end
      }
      # puts "[Fiber:#{fiber.object_id}] appended"
      @waiting_fibers << prepared
      nil
    end

    # Wrap a block to be scheduled by this dataloader
    # @return [Fiber]
    def prepare
      Fiber.new {
        begin
          yield
        rescue StandardError => exception
          exception
        end
      }
    end

    # Tell the dataloader that this fiber is waiting for data.
    # @return [void]
    def yield
      Fiber.yield
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
        result = current_fiber.resume
        if result.is_a?(StandardError)
          raise result
        end
        # puts "[Fiber:#{current_fiber.object_id}] (#{current_fiber.alive? ? "Alive" : "Dead"}) progress: #{progress_f.class}:#{progress_f.object_id}"

        # This fiber yielded; there's more to do here.
        # (If `#alive?` is false, then the fiber concluded without yielding.)
        if current_fiber.alive?
          # puts "[Fiber:#{current_fiber.object_id}] alive, queuing"
          already_run_fibers << current_fiber
        end

        if @waiting_fibers.empty?
          @source_cache.each_value(&:run_pending_keys)
          @waiting_fibers.concat(already_run_fibers)
          already_run_fibers.clear
        end
      end
      nil
    end

    def with(source_class)
      @source_cache[source_class] ||= source_class.new(self)
    end
  end
end
