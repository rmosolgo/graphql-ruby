# frozen_string_literal: true
module GraphQL
  module Introspection
    class InputValueType < Introspection::BaseObject
      graphql_name "__InputValue"
      description "Arguments provided to Fields or Directives and the input fields of an "\
                  "InputObject are represented as Input Values which describe their type and "\
                  "optionally a default value."
      field :name, String, null: false
      field :description, String, null: true
      field :type, GraphQL::Schema::LateBoundType.new("__Type"), null: false
      field :default_value, String, "A GraphQL-formatted string representing the default value for this input value.", null: true
      field :is_deprecated, Boolean, null: false
      field :deprecation_reason, String, null: true

      def is_deprecated
        !!@object.deprecation_reason
      end

      def default_value
        if @object.default_value?
          value = @object.default_value
          if value.nil?
            'null'
          else
            coerced_default_value = @object.type.coerce_result(value, @context)
            serialize_default_value(coerced_default_value, @object.type)
          end
        else
          nil
        end
      end


      private

      # Recursively serialize, taking care not to add quotes to enum values
      def serialize_default_value(value, type)
        if value.nil?
          'null'
        elsif type.kind.list?
          inner_type = type.of_type
          "[" + value.map { |v| serialize_default_value(v, inner_type) }.join(", ") + "]"
        elsif type.kind.non_null?
          serialize_default_value(value, type.of_type)
        elsif type.kind.enum?
          value
        elsif type.kind.input_object?
          "{" +
            value.map do |k, v|
              arg_defn = type.arguments[k]
              "#{k}: #{serialize_default_value(v, arg_defn.type)}"
            end.join(", ") +
            "}"
        else
          GraphQL::Language.serialize(value)
        end
      end
    end
  end
end
