# frozen_string_literal: true
module GraphQL
  module Define
    # Turn field configs into a {GraphQL::Field} and attach it to a {GraphQL::ObjectType} or {GraphQL::InterfaceType}
    module AssignObjectField
      def self.call(owner_type, name, type_or_field = nil, desc = nil, function: nil, field: nil, relay_mutation_function: nil, **kwargs, &block)
        name_s = name.to_s

        # Move some possitional definitions into keyword defns:
        kwargs[:description] ||= desc
        kwargs[:name] ||= name_s

        if !type_or_field.nil? && !type_or_field.is_a?(GraphQL::Field)
          kwargs[:type] = type_or_field
        end

        # Figure out how to find or initialize the field instance:
        field = if type_or_field.is_a?(GraphQL::Field)
          type_or_field.redefine(name: name_s)
        elsif function
          GraphQL::Field.define(
            arguments: function.arguments,
            name: name_s,
            type: function.type,
            resolve: function,
            description: function.description,
            deprecation_reason: function.deprecation_reason,
          )
        elsif block_given?
          GraphQL::Field.define(kwargs, &block)
        elsif field.nil?
          GraphQL::Field.define(kwargs)
        elsif field.is_a?(GraphQL::Field)
          field.redefine(name: name_s)
        else
          raise("Couldn't find a field argument, received: #{field || type_or_field}")
        end

        # Attach the field to the type
        owner_type.fields[name_s] = field
      end
    end
  end
end
