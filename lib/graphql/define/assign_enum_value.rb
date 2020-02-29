# frozen_string_literal: true
module GraphQL
  module Define
    # @api deprecated
    module AssignEnumValue
      def self.call(enum_type, name, desc = nil, deprecation_reason: nil, value: name, &block)
        enum_value = GraphQL::EnumType::EnumValue.define(
          name: name.to_s,
          description: desc,
          deprecation_reason: deprecation_reason,
          value: value,
          &block
        )
        enum_type.add_value(enum_value)
      end
    end
  end
end
