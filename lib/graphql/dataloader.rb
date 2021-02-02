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
    def append_batch(receiver, method, *args)
      args.unshift(method)
      args.unshift(receiver)
      @pending_batches.push(args)
      nil
    end

    # @api private Move along, move along
    def run_batches
      pending_fibers = []
      next_fibers = []

      while @pending_batches.any?
        run_batch_fiber(into: pending_fibers)
      end

      # Now, run all Sources which have become pending _before_ resuming GraphQL execution.
      # Sources might queue up other Sources, which is fine -- those will also run before resuming execution.
      #
      # This is where an evented approach would be even better -- can we tell which
      # fibers are ready to continue, and continue execution there?
      #
      run_all_pending_sources
      next_fibers.concat(pending_fibers)
      pending_fibers.clear
      while (f = next_fibers.shift)
        f.resume
        if f.alive?
          pending_fibers << f
        end

        while @pending_batches.any?
          run_batch_fiber(into: pending_fibers)
        end

        if next_fibers.empty?
          run_all_pending_sources
          next_fibers.concat(pending_fibers)
          pending_fibers.clear
        end
      end
    end

    private

    def run_all_pending_sources
      enqueue_pending_source_batches
      pending_source_fibers = []
      while @pending_batches.any?
        run_batch_fiber(into: pending_source_fibers)
        if @pending_batches.empty?
          enqueue_pending_source_batches
        end
      end

      # Use `.pop` so that any new batch fibers are run first
      while (f = pending_source_fibers.pop)
        f.resume
        enqueue_pending_source_batches
        while @pending_batches.any?
          run_batch_fiber(into: pending_source_fibers)
        end
        if f.alive?
          pending_source_fibers << f
        end
      end
    end

    def enqueue_pending_source_batches
      @source_cache.each_value do |source_by_batch_params|
        source_by_batch_params.each_value do |source|
          if source.pending?
            @pending_batches << [source, :run_pending_keys]
          end
        end
      end
    end

    def run_batch_fiber(into: nil)
      f = Fiber.new {
        while (batch = @pending_batches.shift)
          recv, method, *args = batch
          # p "#{recv.class}##{method.inspect}(#{args.size})"
          recv.public_send(method, *args)
        end
      }
      # Run it until it yields or the batches run out
      result = f.resume
      if result.is_a?(StandardError)
        raise result
      end
      if f.alive? && into
        into << f
      end
      f
    end
  end
end
