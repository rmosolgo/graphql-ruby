# frozen_string_literal: true
# test_via: ../object.rb

module GraphQL
  class Object < GraphQL::SchemaMember
    module Resolvers
      class Dynamic
        def initialize(method_name:)
          @method_name = method_name
        end

        def call(obj, args, ctx)
          if obj.respond_to?(@method_name)
            public_send_field(obj, @method_name, args)
          elsif obj.object.respond_to?(@method_name)
            public_send_field(obj.object, @method_name, args)
          elsif obj.is_a?(Hash)
            obj[@method_name]
          else
            raise <<-ERR
Failed to implement #{ctx.irep_node.owner_type.name}.#{ctx.field.name}, tried:

- `#{obj.class}##{@method_name}`, which did not exist
- `#{obj.object.class}##{@method_name}`, which did not exist
- Looking up hash key `#{@method_name.inspect}` on `#{obj}`, but it wasn't a Hash

To implement this field, define one of the methods above (and check for typos)
ERR
          end
        end

        private

        def public_send_field(obj, method_name, graphql_args)
          if graphql_args.any?
            ruby_kwargs = {}
            graphql_args.to_h.each { |k, v| ruby_kwargs[k.to_sym] = v }
            # Splat the GraphQL::Arguments to Ruby keyword arguments
            # TODO: underscore-ize and apply the transformation deeply.
            obj.public_send(method_name, ruby_kwargs)
          else
            obj.public_send(method_name)
          end
        end
      end
    end
  end
end
