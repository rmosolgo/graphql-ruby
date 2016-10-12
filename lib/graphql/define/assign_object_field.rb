module GraphQL
  module Define
    # Turn field configs into a {GraphQL::Field} and attach it to a {GraphQL::ObjectType} or {GraphQL::InterfaceType}
    module AssignObjectField
      # def self.call(owner_type, name, type_or_field = nil, desc = nil, field: nil, **kwargs, &block)
      ### Ruby 1.9.3 unofficial support
      def self.call(owner_type, name, type_or_field = nil, desc = nil, options = {}, &block)
        field = options.fetch(:field, nil)
        kwargs = options.delete_if { |k, _| k == :field }

        name_s = name.to_s

        # Move some possitional definitions into keyword defns:
        kwargs[:description] ||= desc
        kwargs[:name] ||= name_s

        if !type_or_field.nil? && !type_or_field.is_a?(GraphQL::Field)
          kwargs[:type] = type_or_field
        end

        # Figure out how to find or initialize the field instance:
        if type_or_field.is_a?(GraphQL::Field)
          field = type_or_field
          field.name ||= name_s
        elsif block_given?
          field = GraphQL::Field.define(kwargs, &block)
        elsif field.nil?
          field = GraphQL::Field.define(kwargs)
        elsif field.is_a?(GraphQL::Field)
          field.name ||= name_s
        else
          raise("Couldn't find a field argument, received: #{field || type_or_field}")
        end

        # Attach the field to the type
        owner_type.fields[name_s] = field
      end
    end
  end
end
