# frozen_string_literal: true

require "graphql/dataloader/request"
require "graphql/dataloader/request_all"
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
      def yielded?(_fiber); false; end
    end

    def self.use(schema)
      schema.dataloader_class = self
    end

    def initialize(context)
      @context = context
      @source_cache = Hash.new { |h,k| h[k] = {} }
      @waiting_fibers = []
      @yielded_fibers = Set.new
    end

    # @return [Hash] the {Multiplex} context
    attr_reader :context

    # Add some work to this dataloader to be scheduled later.
    # @param prepared [Fiber] some work prepared with {prepare}
    # @param block Some work to enqueue
    # @return [void]
    def enqueue(prepared = nil, &block)
      prepared ||= prepare(&block)
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
      # This fiber hasn't yielded yet, it should flag
      if !@yielded_fibers.include?(Fiber.current)
        @yielded_fibers.add(Fiber.current)
        progress_ctx = @context[:next_progress]
        next_fiber = progress_ctx[:runtime].make_selections_fiber
        enqueue(next_fiber)
      end
      Fiber.yield
    end

    def yielded?(fiber)
      @yielded_fibers.include?(fiber)
    end

    # Run all Fibers until they're all done
    # @return [void]
    def run
      # Start executing Fibers. This will run until all the Fibers are done.
      already_run_fibers = []
      while (current_fiber = @waiting_fibers.pop)
        # Run this fiber until its next yield.
        # If the Fiber yields, it will return an object for continuing excecution.
        # If it doesn't yield, it will return `nil`
        result = current_fiber.resume
        if result.is_a?(StandardError)
          raise result
        end

        # This fiber yielded; there's more to do here.
        # (If `#alive?` is false, then the fiber concluded without yielding.)
        if current_fiber.alive?
          already_run_fibers << current_fiber
        else
          # Keep this set clean so that fibers can be GC'ed during execution
          @yielded_fibers.delete(current_fiber)
        end

        if @waiting_fibers.empty?
          # Now, run all Sources which have become pending _before_ resuming GraphQL execution.
          # Sources might queue up other Sources, which is fine -- those will also run before resuming execution.
          #
          # This is where an evented approach would be even better -- can we tell which
          # fibers are ready to continue, and continue execution there?
          #
          source_fiber_stack = if (first_source_fiber = create_source_fiber)
            [first_source_fiber]
          else
            nil
          end

          if source_fiber_stack
            while (outer_source_fiber = source_fiber_stack.pop)
              outer_source_fiber.resume
              if outer_source_fiber.alive?
                source_fiber_stack << outer_source_fiber
              else
                # Keep this set clean so that fibers can be GC'ed during execution
                @yielded_fibers.delete(outer_source_fiber)
              end

              # If this source caused more sources to become pending, run those before running this one again:
              next_source_fiber = create_source_fiber
              if next_source_fiber
                source_fiber_stack << next_source_fiber
              end
            end
          end

          @waiting_fibers.concat(already_run_fibers)
          already_run_fibers.clear
        end
      end
      nil
    end

    def with(source_class, *batch_parameters)
      @source_cache[source_class][batch_parameters] ||= source_class.new(self, *batch_parameters)
    end

    private

    # @return [Fiber, nil]
    def create_source_fiber
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
        source_fiber = Fiber.new do
          pending_sources.each(&:run_pending_keys)
        end
      end

      source_fiber
    end
  end
end
