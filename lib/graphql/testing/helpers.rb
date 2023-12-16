# frozen_string_literal: true
module GraphQL
  module Testing
    module Helpers
      # @param schema_class [Class<GraphQL::Schema>]
      # @return [Module] A helpers module which always uses the given schema
      def self.for(schema_class)
        Module.new do
          include SchemaHelpers
          @@schema_class_for_helpers = schema_class
        end
      end

      class Error < GraphQL::Error
      end

      class TypeNotVisibleError < Error
        def initialize(type_name:)
          message = "`#{type_name}` should be `visible?` this field resolution and `context`, but it was not"
          super(message)
        end
      end

      class FieldNotVisibleError < Error
        def initialize(type_name:, field_name:)
          message = "`#{type_name}.#{field_name}` should be `visible?` for this resolution, but it was not"
          super(message)
        end
      end


      def run_graphql_field(schema, field_path, object, arguments: {}, context: {})
        type_name, field_name = field_path.split(".")
        dummy_query = GraphQL::Query.new(schema, context: context)
        query_context = dummy_query.context
        visible_object_type = dummy_query.get_type(type_name) # rubocop:disable Development/ContextIsPassedCop
        if visible_object_type
          visible_field = dummy_query.get_field(visible_object_type, field_name)
          if visible_field
            graphql_object = visible_object_type.wrap(object, query_context)
            result = nil
            field_args = visible_field.coerce_arguments(graphql_object, arguments, query_context)
            dummy_query.context.dataloader.run_isolated {
              result = visible_field.resolve(graphql_object, field_args.keyword_arguments, query_context)
              result = schema.sync_lazy(result)
            }
            result
          else
            raise FieldNotVisibleError.new(field_name: field_name, type_name: type_name)
          end
        else
          raise TypeNotVisibleError.new(type_name: type_name)
        end
      end

      def with_resolution_context(schema, type:, object:, context:{})
        resolution_context = ResolutionAssertionContext.new(
          self,
          schema: schema,
          type_name: type,
          object: object,
          context: context
        )
        yield(resolution_context)
      end

      class ResolutionAssertionContext
        def initialize(test, type_name:, object:, schema:, context:)
          @test = test
          @type_name = type_name
          @object = object
          @schema = schema
          @context = context
        end


        def run_graphql_field(field_name, arguments: {})
          if @schema
            @test.run_graphql_field(@schema, "#{@type_name}.#{field_name}", @object, arguments: arguments, context: @context)
          else
            @test.run_graphql_field("#{@type_name}.#{field_name}", @object, arguments: arguments, context: @context)
          end
        end
      end

      module SchemaHelpers
        include Helpers

        def run_graphql_field(field_path, object, arguments: {}, context: {})
          super(@@schema_class_for_helpers, field_path, object, arguments: arguments, context: context)
        end

        def with_resolution_context(*args, **kwargs, &block)
          # schema will be added later
          super(nil, *args, **kwargs, &block)
        end
      end
    end
  end
end
