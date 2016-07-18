module GraphQL
  class Field
    # Create resolve procs ahead of time based on a {GraphQL::Field}'s `name`, `property`, and `hash_key` configuration.
    module Resolve
      module_function

      # @param [GraphQL::Field] A field that needs a resolve proc
      # @return [Proc] A resolve proc for this field, based on its config
      def create_proc(field)
        if field.property
          method_name = field.property.to_sym
          -> (obj, args, ctx) { obj.public_send(method_name) }
        elsif !field.hash_key.nil?
          key = field.hash_key
          -> (obj, args, ctx) { obj[key] }
        else
          # Name might be defined later, so make the lookup at query-time:
          -> (obj, args, ctx) { obj.public_send(field.name) }
        end
      end
    end
  end
end
