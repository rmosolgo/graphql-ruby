module GraphQL
  module Define
    # Turn field configs into a {GraphQL::Field} and attach it to a {GraphQL::ObjectType} or {GraphQL::InterfaceType}
    module AssignObjectField
      def self.call(fields_type, name, type = nil, desc = nil, field: nil, deprecation_reason: nil, property: nil, &block)
        if block_given?
          field = GraphQL::Field.define(&block)
        else
          field ||= GraphQL::Field.new
        end
        type && field.type = type
        desc && field.description = desc
        property && field.property = property
        deprecation_reason && field.deprecation_reason = deprecation_reason
        field.name ||= name.to_s
        fields_type.fields[name.to_s] = field
      end
    end
  end
end
