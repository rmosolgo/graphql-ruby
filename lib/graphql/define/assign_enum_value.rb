module GraphQL
  module Define
    # Turn enum value configs into a {GraphQL::EnumType::EnumValue} and register it with the {GraphQL::EnumType}
    module AssignEnumValue
      # def self.call(enum_type, name, desc = nil, deprecation_reason: nil, value: name)
      ### Ruby 1.9.3 unofficial support
      def self.call(enum_type, name, desc = nil, options = {})
        deprecation_reason = options.fetch(:deprecation_reason, nil)
        value = options.fetch(:value, name)

        enum_value = GraphQL::EnumType::EnumValue.new(
          name: name,
          description: desc,
          deprecation_reason: deprecation_reason,
          value: value
        )
        enum_type.add_value(enum_value)
      end
    end
  end
end
