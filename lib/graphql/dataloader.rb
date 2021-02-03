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

    def debug_batch(recv, meth, *args, extra: "")
      return # turned off
      debug_args = args.map do |arg|
        case arg
        when String, Integer, Float, true, false
          arg
        else
          arg.class
        end
      end

      p "#{extra}#{recv.class}##{meth}(#{args.size}: #{debug_args}}"
    end

    def initialize(multiplex_context)
      @context = multiplex_context
      @source_cache = Hash.new { |h, source_class| h[source_class] = Hash.new { |h2, batch_parameters|
          source = source_class.new(*batch_parameters)
          source.setup(self)
          h2[batch_parameters] = source
        }
      }
      @pending_batches = []
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

    # @return [Hash] the {Multiplex} context
    attr_reader :context

    # Tell the dataloader that this fiber is waiting for data.
    #
    # Dataloader will resume the fiber after the requested data has been loaded (by another Fiber).
    #
    # @return [void]
    def yield
      Fiber.yield
      nil
    end

    # @api private Nothing to see here
    def append_batch(*batch)
      @pending_batches.push(batch)
      nil
    end

    # @api private Move along, move along
    def run_batches
      pending_fibers = []
      next_fibers = []
      first_pass = true

      while first_pass || (f = pending_fibers.shift)
        if first_pass
          first_pass = false
        else
          f.resume
          if f.alive?
            next_fibers << f
          end
        end

        while @pending_batches.any?
          f = Fiber.new {
            while (batch = @pending_batches.shift)
              debug_batch(*batch, extra: "Execute: ")
              recv, method, *args = batch
              recv.public_send(method, *args)
            end
          }
          # Run it until it yields or the batches run out
          result = f.resume
          if result.is_a?(StandardError)
            raise result
          end
          if f.alive?
            next_fibers << f
          end
        end

        if pending_fibers.empty?
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
              result = outer_source_fiber.resume
              if result.is_a?(StandardError)
                raise result
              end

              if outer_source_fiber.alive?
                source_fiber_stack << outer_source_fiber
              end
              # If this source caused more sources to become pending, run those before running this one again:
              next_source_fiber = create_source_fiber
              if next_source_fiber
                source_fiber_stack << next_source_fiber
              end
            end
          end
          pending_fibers.concat(next_fibers)
          next_fibers.clear
        end
      end

      if @pending_batches.any?
        raise "Invariant: #{@pending_batches.size} pending batches"
      elsif pending_fibers.any?
        raise "Invariant: #{pending_fibers.size} pending fibers"
      elsif next_fibers.any?
        raise "Invariant: #{next_fibers.size} next fibers"
      end
      nil
    end

    private

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
