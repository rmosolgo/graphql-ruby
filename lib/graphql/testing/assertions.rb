# frozen_string_literal: true
module GraphQL
  module Testing
    module Assertions
      def self.for(schema_class)
        Module.new do
          include SchemaAssertions
          @@schema_class_for_assertions = schema_class
        end
      end

      def assert_resolves_type_to(schema, expected_type, value, context = {}, message = nil)
        message ||= "#{schema} resolves #{value.inspect} to #{expected_type.inspect}"
        resolved_type = schema.resolve_type(nil, value, context)
        resolved_type, _value = schema.sync_lazy(resolved_type)
        warden = schema.warden_class.new(schema: schema, context: context)
        visible_type = warden.get_type(resolved_type.graphql_name)
        if expected_type.nil?
          assert_nil visible_type, message
        else
          case visible_type
          when nil
            assert_equal expected_type, visible_type, message + " (`#{expected_type.graphql_name}` was not `visible?` for this `context`)"
          when expected_type
            # pass
          else
            assert_equal expected_type, resolved_type, message
          end
        end
      end

      def assert_resolves_field_to(schema, expected_value, type, field, object, arguments: {}, context: {}, message: nil)
        dummy_query = GraphQL::Query.new(schema, context: context)
        type_name = type.is_a?(String) ? type : type.graphql_name
        visible_object_type = dummy_query.get_type(type_name)
        if visible_object_type
          field_name = field.is_a?(String) ? field : field.graphql_name
          visible_field = dummy_query.get_field(visible_object_type, field_name)
          if visible_field.nil?
            assert visible_field, "`#{type_name}.#{field_name}` should be `visible?` for this resolution, but it was not"
          else
            graphql_object = visible_object_type.wrap(object, dummy_query.context)
            result = visible_field.resolve(graphql_object, arguments, dummy_query.context)
            result = schema.sync_lazy(result)
            # TODO dataloader
            assert_equal expected_value, result, "#{visible_field.path} resolved to #{expected_value.inspect} for #{object.inspect}"
          end
        else
          assert visible_object_type, "`#{type}` should be `visible?` this field resolution and `context`, but it was not"
        end
      end

      module SchemaAssertions
        include Assertions

        module ClassMethods
          attr_accessor :schema_class_for_assertions
        end

        def assert_resolves_type_to(*args, **kwargs, &block)
          super(@@schema_class_for_assertions, *args, **kwargs, &block)
        end

        def assert_resolves_field_to(*args, **kwargs, &block)
          super(@@schema_class_for_assertions, *args, **kwargs, &block)
        end
      end
    end
  end
end
