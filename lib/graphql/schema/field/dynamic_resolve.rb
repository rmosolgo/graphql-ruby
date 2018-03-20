# frozen_string_literal: true

module GraphQL
  class Schema
    class Field
      class DynamicResolve
        def initialize(method_name:, connection:, extras:)
          @method_name = method_name
          @method_sym = method_name.to_sym
          @connection = connection
          @extras = extras
        end

        def call(obj, args, ctx)
          if obj.respond_to?(@method_name)
            public_send_field(obj, @method_name, args, ctx)
          elsif obj.object.respond_to?(@method_name)
            public_send_field(obj.object, @method_name, args, ctx)
          elsif obj.object.is_a?(Hash)
            inner_object = obj.object
            inner_object[@method_name] || inner_object[@method_sym]
          else
            raise <<-ERR
Failed to implement #{ctx.irep_node.owner_type.name}.#{ctx.field.name}, tried:

- `#{obj.class}##{@method_name}`, which did not exist
- `#{obj.object.class}##{@method_name}`, which did not exist
- Looking up hash key `#{@method_name.inspect}` on `#{obj.object}`, but it wasn't a Hash

To implement this field, define one of the methods above (and check for typos)
ERR
          end
        end

        private

        NO_ARGS = {}.freeze

        def public_send_field(obj, method_name, graphql_args, field_ctx)
          if graphql_args.any? || @extras.any?
            # Splat the GraphQL::Arguments to Ruby keyword arguments
            ruby_kwargs = graphql_args.to_kwargs

            if @connection
              # Remove pagination args before passing it to a user method
              ruby_kwargs.delete(:first)
              ruby_kwargs.delete(:last)
              ruby_kwargs.delete(:before)
              ruby_kwargs.delete(:after)
            end

            @extras.each do |extra_arg|
              # TODO: provide proper tests for `:ast_node`, `:irep_node`, `:parent`, others?
              ruby_kwargs[extra_arg] = field_ctx.public_send(extra_arg)
            end
          else
            ruby_kwargs = NO_ARGS
          end


          if ruby_kwargs.any?
            obj.public_send(method_name, ruby_kwargs)
          else
            obj.public_send(method_name)
          end
        end
      end
    end
  end
end
