# frozen_string_literal: true
module GraphQL
  module Introspection
    class TypeType < Introspection::BaseObject
      graphql_name "__Type"
      description "The fundamental unit of any GraphQL Schema is the type. There are many kinds of types in "\
                  "GraphQL as represented by the `__TypeKind` enum.\n\n"\
                  "Depending on the kind of a type, certain fields describe information about that type. "\
                  "Scalar types provide no information beyond a name and description, while "\
                  "Enum types provide their values. Object and Interface types provide the fields "\
                  "they describe. Abstract types, Union and Interface, provide the Object types "\
                  "possible at runtime. List and NonNull types compose other types."

      field :kind, GraphQL::Schema::LateBoundType.new("__TypeKind"), null: false, resolve_each: :resolve_kind
      field :name, String, method: :graphql_name
      field :description, String
      field :fields, [GraphQL::Schema::LateBoundType.new("__Field")], scope: false, resolve_each: :resolve_fields do
        argument :include_deprecated, Boolean, required: false, default_value: false
      end
      field :interfaces, [GraphQL::Schema::LateBoundType.new("__Type")], scope: false, resolve_each: :resolve_interfaces
      field :possible_types, [GraphQL::Schema::LateBoundType.new("__Type")], scope: false, resolve_each: :resolve_possible_types
      field :enum_values, [GraphQL::Schema::LateBoundType.new("__EnumValue")], scope: false, resolve_each: :resolve_enum_values do
        argument :include_deprecated, Boolean, required: false, default_value: false
      end
      field :input_fields, [GraphQL::Schema::LateBoundType.new("__InputValue")], scope: false, resolve_each: :resolve_input_fields  do
        argument :include_deprecated, Boolean, required: false, default_value: false
      end
      field :of_type, GraphQL::Schema::LateBoundType.new("__Type"), resolve_each: :resolve_of_type

      field :specifiedByURL, String, resolve_each: :resolve_specified_by_url, resolver_method: :specified_by_url

      field :is_one_of, Boolean, null: false, resolve_each: :resolve_is_one_of

      def self.resolve_is_one_of(object, _ctx)
        object.kind.input_object? &&
          object.directives.any? { |d| d.graphql_name == "oneOf" }
      end

      def is_one_of
        self.class.resolve_is_one_of(object, context)
      end

      def self.resolve_specified_by_url(object, _ctx)
        if object.kind.scalar?
          object.specified_by_url
        else
          nil
        end
      end

      def specified_by_url
        self.class.resolve_specified_by_url(object, context)
      end

      def self.resolve_kind(object, context)
        object.kind.name
      end

      def kind
        self.class.resolve_kind(object, context)
      end

      def self.resolve_enum_values(object, context, include_deprecated:)
        if !object.kind.enum?
          nil
        else
          enum_values = context.types.enum_values(object)

          if !include_deprecated
            enum_values = enum_values.select {|f| !f.deprecation_reason }
          end

          enum_values
        end
      end

      def enum_values(include_deprecated:)
        self.class.resolve_enum_values(object, context, include_deprecated: include_deprecated)
      end

      def self.resolve_interfaces(object, context)
        if object.kind.object? || object.kind.interface?
          context.types.interfaces(object).sort_by(&:graphql_name)
        else
          nil
        end
      end

      def interfaces
        self.class.resolve_interfaces(object, context)
      end

      def self.resolve_input_fields(object, context, include_deprecated:)
        if object.kind.input_object?
          args = context.types.arguments(object)
          args = args.reject(&:deprecation_reason) unless include_deprecated
          args
        else
          nil
        end
      end

      def input_fields(include_deprecated:)
        self.class.resolve_input_fields(object, context, include_deprecated: include_deprecated)
      end

      def self.resolve_possible_types(object, context)
        if object.kind.abstract?
          context.types.possible_types(object).sort_by(&:graphql_name)
        else
          nil
        end
      end

      def possible_types
        self.class.resolve_possible_types(object, context)
      end

      def self.resolve_fields(object, context, include_deprecated:)
        if !object.kind.fields?
          nil
        else
          fields = context.types.fields(object)
          if !include_deprecated
            fields = fields.select {|f| !f.deprecation_reason }
          end
          fields.sort_by(&:name)
        end
      end

      def fields(include_deprecated:)
        self.class.resolve_fields(object, context, include_deprecated: include_deprecated)
      end

      def self.resolve_of_type(object, _ctx)
        object.kind.wraps? ? object.of_type : nil
      end

      def of_type
        self.class.resolve_of_type(object, context)
      end
    end
  end
end
