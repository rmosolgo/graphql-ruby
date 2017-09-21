# frozen_string_literal: true
module GraphQL
  module Define
    # Turn field configs into a {GraphQL::Field} and attach it to a {GraphQL::ObjectType} or {GraphQL::InterfaceType}
    module AssignObjectField
      def self.call(owner_type, name, type_or_field = nil, desc = nil, function: nil, field: nil, relay_mutation_function: nil, **kwargs, &block)
        name_s = name.to_s

        # Move some positional args into keywords if they're present
        desc && kwargs[:description] ||= desc
        name && kwargs[:name] ||= name_s

        if !type_or_field.nil? && !type_or_field.is_a?(GraphQL::Field)
          # Maybe a string, proc or BaseType
          kwargs[:type] = type_or_field
        end

        base_field = if type_or_field.is_a?(GraphQL::Field)
          type_or_field.redefine(name: name_s)
        elsif function
          kwargs = {
            arguments: function.arguments,
            name: name_s,
            type: function.type,
            resolve: function,
            description: function.description,
            function: function,
            deprecation_reason: function.deprecation_reason,
          }
          kwargs[:complexity] = function.complexity if function.complexity

          GraphQL::Field.define(**kwargs)
        elsif field.is_a?(GraphQL::Field)
          field.redefine(name: name_s)
        else
          nil
        end

        field = if base_field
          base_field.redefine(kwargs, &block)
        else
          GraphQL::Field.define(kwargs, &block)
        end


        # Attach the field to the type
        owner_type.fields[name_s] = field
      end
    end
  end
end
