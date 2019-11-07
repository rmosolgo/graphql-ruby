# frozen_string_literal: true
require "graphql/dataloader/loader"

module GraphQL
  class Dataloader
    def self.use(schema)
      instrumenter = Dataloader::Instrumentation.new(
        dataloader_class: self,
      )
      schema.instrument(:multiplex, instrumenter)
      # TODO clean this up when we can assume it's a class-based schema
      if !schema.is_a?(Class)
        schema = schema.target.class
      end
      schema.mutation.fields.each do |name, field|
        field.metadata[:type_class].extension(MutationFieldExtension)
      end
    end

    class MutationFieldExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, context:, **_rest)
        context[:dataloader].clear
        begin
          return_value = yield(object, arguments)
          GraphQL::Execution::Lazy.sync(return_value)
        ensure
          context[:dataloader].clear
        end
      end
    end

    class Instrumentation
      def initialize(dataloader_class:)
        @dataloader_class = dataloader_class
      end

      def before_multiplex(multiplex)
        dl = @dataloader_class.new(multiplex)
        multiplex.context[:dataloader] = dl
        multiplex.queries.each do |q|
          q.context[:dataloader] = dl
        end
      end

      def after_multiplex(_m)
      end
    end

    attr_reader :loaders

    def initialize(multiplex)
      @multiplex = multiplex

      @loaders = Hash.new do |h, loader_cls|
        h[loader_cls] = Hash.new do |h2, loader_key|
          h2[loader_key] = loader_cls.new(@multiplex.context, *loader_key)
        end
      end
    end

    def clear
      @loaders.clear
    end
  end
end
