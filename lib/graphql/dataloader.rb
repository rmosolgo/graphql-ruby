# frozen_string_literal: true

require "graphql/dataloader/null_dataloader"
require "graphql/dataloader/request"
require "graphql/dataloader/request_all"
require "graphql/dataloader/source"

module GraphQL
  # This plugin supports Fiber-based concurrency, along with {GraphQL::Dataloader::Source}.
  #
  # @example Installing Dataloader
  #
  #   class MySchema < GraphQL::Schema
  #     use GraphQL::Dataloader
  #   end
  #
  # @example Waiting for batch-loaded data in a GraphQL field
  #
  #   field :team, Types::Team, null: true
  #
  #   def team
  #     dataloader.with(Sources::Record, Team).load(object.team_id)
  #   end
  #
  class Dataloader
    def self.use(schema)
      schema.dataloader_class = self
    end

    def initialize(multiplex_context)
      @context = multiplex_context
      @source_cache = Hash.new { |h, source_class| h[source_class] = Hash.new { |h2, batch_parameters|
          source = source_class.new(*batch_parameters)
          source.setup(self)
          h2[batch_parameters] = source
        }
      }
      @waiting_fibers = []
      @yielded_fibers = Set.new
    end

    # @return [Hash] the {Multiplex} context
    attr_reader :context

    # @api private
    attr_reader :yielded_fibers

    # Add some work to this dataloader to be scheduled later.
    # @param block Some work to enqueue
    # @return [void]
    def enqueue(&block)
      @waiting_fibers << Fiber.new {
        begin
          yield
        rescue StandardError => exception
          exception
        end
      }
      nil
    end

    # Tell the dataloader that this fiber is waiting for data.
    #
    # Dataloader will resume the fiber after the requested data has been loaded (by another Fiber).
    #
    # @return [void]
    def yield
      Fiber.yield
      nil
    end

    # @return [Boolean] Returns true if the current Fiber has yielded once via Dataloader
    def yielded?
      @yielded_fibers.include?(Fiber.current)
    end

    # Run all Fibers until they're all done
    #
    # Each cycle works like this:
    #
    #   - Run each pending execution fiber (`@waiting_fibers`),
    #   - Then run each pending Source, preparing more data for those fibers.
    #     - Run each pending Source _again_ (if one Source requested more data from another Source)
    #     - Continue until there are no pending sources
    #   - Repeat: run execution fibers again ...
    #
    # @return [void]
    def run
      # Start executing Fibers. This will run until all the Fibers are done.
      already_run_fibers = []
      while (current_fiber = @waiting_fibers.pop)
        # Run each execution fiber, enqueuing it in `already_run_fibers`
        # if it's still `.alive?`.
        # Any spin-off continuations will be enqueued in `@waiting_fibers` (via {#enqueue})
        resume_fiber_and_enqueue_continuation(current_fiber, already_run_fibers)

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
              resume_fiber_and_enqueue_continuation(outer_source_fiber, source_fiber_stack)

              # If this source caused more sources to become pending, run those before running this one again:
              next_source_fiber = create_source_fiber
              if next_source_fiber
                source_fiber_stack << next_source_fiber
              end
            end
          end

          # We ran all the first round of execution fibers,
          # and we ran all the pending sources.
          # So pick up any paused execution fibers and repeat.
          @waiting_fibers.concat(already_run_fibers)
          already_run_fibers.clear
        end
      end
      nil
    end

    # Get a Source instance from this dataloader, for calling `.load(...)` or `.request(...)` on.
    #
    # @param source_class [Class<GraphQL::Dataloader::Source]
    # @param batch_parameters [Array<Object>]
    # @return [GraphQL::Dataloader::Source] An instance of {source_class}, initialized with `self, *batch_parameters`,
    #   and cached for the lifetime of this {Multiplex}.
    def with(source_class, *batch_parameters)
      @source_cache[source_class][batch_parameters]
    end

    # @api private
    attr_accessor :current_runtime

    private

    # Check if this fiber is still alive.
    # If it is, and it should continue, then enqueue a continuation.
    # If it is, re-enqueue it in `fiber_queue`.
    # Otherwise, clean it up from @yielded_fibers.
    # @return [void]
    def resume_fiber_and_enqueue_continuation(fiber, fiber_stack)
      result = fiber.resume
      if result.is_a?(StandardError)
        raise result
      end

      # This fiber yielded; there's more to do here.
      # (If `#alive?` is false, then the fiber concluded without yielding.)
      if fiber.alive?
        if !@yielded_fibers.include?(fiber)
          # This fiber hasn't yielded yet, we should enqueue a continuation fiber
          @yielded_fibers.add(fiber)
          current_runtime.enqueue_selections_fiber
        end
        fiber_stack << fiber
      else
        # Keep this set clean so that fibers can be GC'ed during execution
        @yielded_fibers.delete(fiber)
      end
    end

    # If there are pending sources, return a fiber for running them.
    # Otherwise, return `nil`.
    #
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
