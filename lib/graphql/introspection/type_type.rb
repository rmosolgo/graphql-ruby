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

      field :kind, GraphQL::Schema::LateBoundType.new("__TypeKind"), null: false
      field :name, String, null: true
      field :description, String, null: true
      field :fields, [GraphQL::Schema::LateBoundType.new("__Field")], null: true do
        argument :include_deprecated, Boolean, required: false, default_value: false
      end
      field :interfaces, [GraphQL::Schema::LateBoundType.new("__Type")], null: true
      field :possible_types, [GraphQL::Schema::LateBoundType.new("__Type")], null: true
      field :enum_values, [GraphQL::Schema::LateBoundType.new("__EnumValue")], null: true do
        argument :include_deprecated, Boolean, required: false, default_value: false
      end
      field :input_fields, [GraphQL::Schema::LateBoundType.new("__InputValue")], null: true  do
        argument :include_deprecated, Boolean, required: false, default_value: false
      end
      field :of_type, GraphQL::Schema::LateBoundType.new("__Type"), null: true

      def name
        object.graphql_name
      end

      def kind
        @object.kind.name
      end

      def enum_values(include_deprecated:)
        if !@object.kind.enum?
          nil
        else
          enum_values = @context.warden.enum_values(@object)

          if !include_deprecated
            enum_values = enum_values.select {|f| !f.deprecation_reason }
          end

          enum_values
        end
      end

      def interfaces
        if @object.kind == GraphQL::TypeKinds::OBJECT
          @context.warden.interfaces(@object)
        else
          nil
        end
      end

      def input_fields(include_deprecated:)
        if @object.kind.input_object?
          args = @context.warden.arguments(@object)
          args = args.reject(&:deprecation_reason) unless include_deprecated
          args
        else
          nil
        end
      end

      def possible_types
        if @object.kind.abstract?
          @context.warden.possible_types(@object).sort_by(&:graphql_name)
        else
          nil
        end
      end

      def fields(include_deprecated:)
        if !@object.kind.fields?
          nil
        else
          fields = @context.warden.fields(@object)
          if !include_deprecated
            fields = fields.select {|f| !f.deprecation_reason }
          end
          fields.sort_by(&:name)
        end
      end

      def of_type
        @object.kind.wraps? ? @object.of_type : nil
      end
    end
  end
end
