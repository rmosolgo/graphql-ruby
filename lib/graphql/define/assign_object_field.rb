module GraphQL
  module Define
    # Turn field configs into a {GraphQL::Field} and attach it to a {GraphQL::ObjectType} or {GraphQL::InterfaceType}
    module AssignObjectField
      def self.call(fields_type, name, type_or_field = nil, desc = nil, field: nil, deprecation_reason: nil, property: nil, complexity: nil, &block)
        if type_or_field.is_a?(GraphQL::Field)
          field = type_or_field
        elsif block_given?
          field = GraphQL::Field.define(&block)
        elsif field.nil?
          field = GraphQL::Field.new
        end

        if !type_or_field.nil? && !type_or_field.is_a?(GraphQL::Field)
          field.type = type_or_field
        end

        desc && field.description = desc
        property && field.property = property
        complexity && field.complexity = complexity
        deprecation_reason && field.deprecation_reason = deprecation_reason
        field.name ||= name.to_s
        fields_type.fields[name.to_s] = field
      end
    end
  end
end
