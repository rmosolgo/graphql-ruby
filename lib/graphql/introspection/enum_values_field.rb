# frozen_string_literal: true
GraphQL::Introspection::EnumValuesField = GraphQL::Field.define do
  type types[!GraphQL::Introspection::EnumValueType]
  argument :includeDeprecated, types.Boolean, default_value: false
  resolve ->(object, arguments, context) do
    if !object.kind.enum?
      nil
    else
      enum_values = context.warden.enum_values(object)

      if !arguments["includeDeprecated"]
        enum_values = enum_values.select {|f| !f.deprecation_reason }
      end

      enum_values
    end
  end
end
