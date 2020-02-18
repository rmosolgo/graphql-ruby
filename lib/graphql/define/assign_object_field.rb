# frozen_string_literal: true
module GraphQL
  module Define
    # @api deprecated
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
          func_field = GraphQL::Function.build_field(function)
          func_field.name = name_s
          func_field
        elsif field.is_a?(GraphQL::Field)
          field.redefine(name: name_s)
        else
          nil
        end

        obj_field = if base_field
          base_field.redefine(**kwargs, &block)
        else
          GraphQL::Field.define(**kwargs, &block)
        end


        # Attach the field to the type
        owner_type.fields[name_s] = obj_field
      end
    end
  end
end
