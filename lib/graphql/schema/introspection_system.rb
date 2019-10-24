# frozen_string_literal: true
module GraphQL
  class Schema
    class IntrospectionSystem
      attr_reader :schema_type, :type_type, :typename_field

      def initialize(schema)
        @schema = schema
        @built_in_namespace = GraphQL::Introspection
        @custom_namespace = schema.introspection_namespace || @built_in_namespace

        # Use to-graphql to avoid sharing with any previous instantiations
        @schema_type = load_constant(:SchemaType).to_graphql
        @type_type = load_constant(:TypeType).to_graphql
        @field_type = load_constant(:FieldType).to_graphql
        @directive_type = load_constant(:DirectiveType).to_graphql
        @enum_value_type = load_constant(:EnumValueType).to_graphql
        @input_value_type = load_constant(:InputValueType).to_graphql
        @type_kind_enum = load_constant(:TypeKindEnum).to_graphql
        @directive_location_enum = load_constant(:DirectiveLocationEnum).to_graphql
        @entry_point_fields =
          if schema.disable_introspection_entry_points
            {}
          else
            get_fields_from_class(class_sym: :EntryPoints)
          end
        @dynamic_fields = get_fields_from_class(class_sym: :DynamicFields)
      end

      def object_types
        [
          @schema_type,
          @type_type,
          @field_type,
          @directive_type,
          @enum_value_type,
          @input_value_type,
          @type_kind_enum,
          @directive_location_enum,
        ]
      end

      def entry_points
        @entry_point_fields.values
      end

      def entry_point(name:)
        @entry_point_fields[name]
      end

      def dynamic_fields
        @dynamic_fields.values
      end

      def dynamic_field(name:)
        @dynamic_fields[name]
      end

      private

      def load_constant(class_name)
        @custom_namespace.const_get(class_name)
      rescue NameError
        # Dup the built-in so that the cached fields aren't shared
        @built_in_namespace.const_get(class_name)
      end

      def get_fields_from_class(class_sym:)
        object_class = load_constant(class_sym)
        object_type_defn = object_class.to_graphql
        extracted_field_defns = {}
        object_type_defn.all_fields.each do |field_defn|
          inner_resolve = field_defn.resolve_proc
          resolve_with_instantiate = PerFieldProxyResolve.new(object_class: object_class, inner_resolve: inner_resolve)
          extracted_field_defns[field_defn.name] = field_defn.redefine(resolve: resolve_with_instantiate)
        end
        extracted_field_defns
      end

      class PerFieldProxyResolve
        def initialize(object_class:, inner_resolve:)
          @object_class = object_class
          @inner_resolve = inner_resolve
        end

        def call(obj, args, ctx)
          query_ctx = ctx.query.context
          # Remove the QueryType wrapper
          if obj.is_a?(GraphQL::Schema::Object)
            obj = obj.object
          end
          wrapped_object = @object_class.authorized_new(obj, query_ctx)
          @inner_resolve.call(wrapped_object, args, ctx)
        end
      end
    end
  end
end
