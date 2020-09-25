# frozen_string_literal: true
require "graphql/dataloader/source"

module GraphQL
  class Dataloader
    class LoadError < GraphQL::Error
      attr_accessor :graphql_path

      attr_writer :message

      def message
        @message || super
      end

      attr_writer :cause

      def cause
        @cause || super
      end
    end

    def self.use(schema)
      instrumenter = Dataloader::Instrumentation.new
      schema.instrument(:multiplex, instrumenter)
      # TODO this won't work if the mutation is hooked up after this
      schema.mutation.fields.each do |name, field|
        field.extension(MutationFieldExtension)
      end
    end

    def self.load(dataloader = Dataloader.new(nil))
      result = begin
        begin_dataloading(dataloader)
        yield
      ensure
        end_dataloading
      end

      GraphQL::Execution::Lazy.sync(result)
    end

    def self.begin_dataloading(dataloader)
      self.current ||= dataloader
      increment_level
    end

    def self.end_dataloading
      decrement_level
      if level < 1
        self.current = nil
      end
    end

    class MutationFieldExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, context:, **_rest)
        Dataloader.current.clear
        begin
          return_value = yield(object, arguments)
          GraphQL::Execution::Lazy.sync(return_value)
        ensure
          Dataloader.current.clear
        end
      end
    end

    class Instrumentation
      def before_multiplex(multiplex)
        dataloader = Dataloader.new(multiplex)
        Dataloader.begin_dataloading(dataloader)
      end

      def after_multiplex(_m)
        Dataloader.end_dataloading
      end
    end

    class << self
      def current
        Thread.current[:graphql_dataloader]
      end

      def current=(dataloader)
        Thread.current[:graphql_dataloader] = dataloader
      end

      def level
        @level || 0
      end

      def increment_level
        @level ||= 0
        @level += 1
      end

      def decrement_level
        @level ||= 0
        @level -= 1
      end
    end

    def initialize(multiplex)
      @multiplex = multiplex

      @sources = Concurrent::Map.new do |h, source_class|
        h[source_class] = Concurrent::Map.new do |h2, source_key|
          h2[source_key] = source_class.new(*source_key)
        end
      end

      @async_source_queue = []
    end

    # @return [Dataloader::Source] an instance of `source_class` for `key`, cached for the duration of the multiplex
    def source_for(source_class, source_key)
      @sources[source_class][source_key]
    end

    def current_query
      @multiplex.context[:current_query]
    end

    def clear
      @sources.clear
    end

    def enqueue_async_source(source)
      if !@async_source_queue.include?(source)
        @async_source_queue << source
      end
    end

    def process_async_source_queue
      queue = @async_source_queue
      @async_source_queue = []
      queue.each(&:wait)
    end
  end
end
