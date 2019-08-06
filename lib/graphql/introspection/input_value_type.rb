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

      def default_value
        if @object.default_value?
          value = @object.default_value
          if value.nil?
            'null'
          else
            coerced_default_value = @object.type.coerce_result(value, @context)
            if @object.type.unwrap.is_a?(GraphQL::EnumType)
              if @object.type.list? 
                "[#{coerced_default_value.join(", ")}]"
              else
                coerced_default_value
              end
            else
              GraphQL::Language.serialize(coerced_default_value)
            end
          end
        else
          nil
        end
      end
    end
  end
end
