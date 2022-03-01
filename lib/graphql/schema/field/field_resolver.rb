# frozen_string_literal: true

module GraphQL
  class Schema
    class Field
      module FieldResolver
        # @return [Symbol, nil] Method or hash key on the underlying object to look up
        attr_reader :method_sym

        # @return [String, nil] Method or hash key on the underlying object to look up
        attr_reader :method_str

        # @return [Symbol] The method on the type to look up
        attr_reader :resolver_method

        # @return [Class, nil] The {Schema::Resolver} this field was derived from, if there is one
        attr_reader :resolver_class
        alias_attribute :resolver, :resolver_class
        alias_attribute :mutation, :resolver_class

        # :hash_keys, :dig_keys

        # This method is called by the interpreter for each field.
        # You can extend it in your base field classes.
        # @param object [GraphQL::Schema::Object] An instance of some type class, wrapping an application object
        # @param args [Hash] A symbol-keyed hash of Ruby keyword arguments. (Empty if no args)
        # @param ctx [GraphQL::Query::Context]
        def resolve(object, args, query_ctx)
          # Unwrap the GraphQL object to get the application object.
          application_object = object.object
          method_receiver = nil
          method_to_call = nil
          method_args = nil

          Schema::Validator.validate!(validators, application_object, query_ctx, args)

          query_ctx.schema.after_lazy(self.authorized?(application_object, args, query_ctx)) do |is_authorized|
            if is_authorized
              with_extensions(object, args, query_ctx) do |obj, ruby_kwargs|
                method_args = ruby_kwargs
                if @resolver_class
                  if obj.is_a?(GraphQL::Schema::Object)
                    obj = obj.object
                  end
                  obj = @resolver_class.new(object: obj, context: query_ctx, field: self)
                end

                # Find a way to resolve this field, checking:
                #
                # - A method on the type instance;
                # - Hash keys, if the wrapped object is a hash;
                # - A method on the wrapped object;
                # - Or, raise not implemented.
                #
                if obj.respond_to?(resolver_method)
                  method_to_call = resolver_method
                  method_receiver = obj
                  # Call the method with kwargs, if there are any
                  if ruby_kwargs.any?
                    obj.public_send(resolver_method, **ruby_kwargs)
                  else
                    obj.public_send(resolver_method)
                  end
                elsif obj.object.is_a?(Hash)
                  inner_object = obj.object
                  if @dig_keys
                    inner_object.dig(*@dig_keys)
                  elsif inner_object.key?(@method_sym)
                    inner_object[@method_sym]
                  else
                    inner_object[@method_str]
                  end
                elsif obj.object.respond_to?(@method_sym)
                  method_to_call = @method_sym
                  method_receiver = obj.object
                  if ruby_kwargs.any?
                    obj.object.public_send(@method_sym, **ruby_kwargs)
                  else
                    obj.object.public_send(@method_sym)
                  end
                else
                  raise <<-ERR
                Failed to implement #{@owner.graphql_name}.#{@name}, tried:

                - `#{obj.class}##{resolver_method}`, which did not exist
                - `#{obj.object.class}##{@method_sym}`, which did not exist
                - Looking up hash key `#{@method_sym.inspect}` or `#{@method_str.inspect}` on `#{obj.object}`, but it wasn't a Hash

                To implement this field, define one of the methods above (and check for typos)
                ERR
                end
              end
            else
              raise GraphQL::UnauthorizedFieldError.new(object: application_object, type: object.class, context: query_ctx, field: self)
            end
          end
        rescue GraphQL::UnauthorizedFieldError => err
          err.field ||= self
          begin
            query_ctx.schema.unauthorized_field(err)
          rescue GraphQL::ExecutionError => err
            err
          end
        rescue GraphQL::UnauthorizedError => err
          begin
            query_ctx.schema.unauthorized_object(err)
          rescue GraphQL::ExecutionError => err
            err
          end
        rescue ArgumentError
          if method_receiver && method_to_call
            assert_satisfactory_implementation(method_receiver, method_to_call, method_args)
          end
          # if the line above doesn't raise, re-raise
          raise
        end

        # @param ctx [GraphQL::Query::Context]
        def fetch_extra(extra_name, ctx)
          if extra_name != :path && extra_name != :ast_node && respond_to?(extra_name)
            self.public_send(extra_name)
          elsif ctx.respond_to?(extra_name)
            ctx.public_send(extra_name)
          else
            raise GraphQL::RequiredImplementationMissingError, "Unknown field extra for #{self.path}: #{extra_name.inspect}"
          end
        end

        private

        def assert_satisfactory_implementation(receiver, method_name, ruby_kwargs)
          method_defn = receiver.method(method_name)
          unsatisfied_ruby_kwargs = ruby_kwargs.dup
          unsatisfied_method_params = []
          encountered_keyrest = false
          method_defn.parameters.each do |(param_type, param_name)|
            case param_type
            when :key
              unsatisfied_ruby_kwargs.delete(param_name)
            when :keyreq
              if unsatisfied_ruby_kwargs.key?(param_name)
                unsatisfied_ruby_kwargs.delete(param_name)
              else
                unsatisfied_method_params << "- `#{param_name}:` is required by Ruby, but not by GraphQL. Consider `#{param_name}: nil` instead, or making this argument required in GraphQL."
              end
            when :keyrest
              encountered_keyrest = true
            when :req
              unsatisfied_method_params << "- `#{param_name}` is required by Ruby, but GraphQL doesn't pass positional arguments. If it's meant to be a GraphQL argument, use `#{param_name}:` instead. Otherwise, remove it."
            when :opt, :rest
              # This is fine, although it will never be present
            end
          end

          if encountered_keyrest
            unsatisfied_ruby_kwargs.clear
          end

          if unsatisfied_ruby_kwargs.any? || unsatisfied_method_params.any?
            raise FieldImplementationFailed.new, <<-ERR
  Failed to call #{method_name} on #{receiver.inspect} because the Ruby method params were incompatible with the GraphQL arguments:

  #{ unsatisfied_ruby_kwargs
      .map { |key, value| "- `#{key}: #{value}` was given by GraphQL but not defined in the Ruby method. Add `#{key}:` to the method parameters." }
      .concat(unsatisfied_method_params)
      .join("\n") }
  ERR
          end
        end

        # Wrap execution with hooks.
        # Written iteratively to avoid big stack traces.
        # @return [Object] Whatever the
        def with_extensions(obj, args, ctx)
          if @extensions.empty?
            yield(obj, args)
          else
            # This is a hack to get the _last_ value for extended obj and args,
            # in case one of the extensions doesn't `yield`.
            # (There's another implementation that uses multiple-return, but I'm wary of the perf cost of the extra arrays)
            extended = { args: args, obj: obj, memos: nil, added_extras: nil }
            value = run_extensions_before_resolve(obj, args, ctx, extended) do |obj, args|
              if (added_extras = extended[:added_extras])
                args = args.dup
                added_extras.each { |e| args.delete(e) }
              end
              yield(obj, args)
            end

            extended_obj = extended[:obj]
            extended_args = extended[:args]
            memos = extended[:memos] || EMPTY_HASH

            ctx.schema.after_lazy(value) do |resolved_value|
              idx = 0
              @extensions.each do |ext|
                memo = memos[idx]
                # TODO after_lazy?
                resolved_value = ext.after_resolve(object: extended_obj, arguments: extended_args, context: ctx, value: resolved_value, memo: memo)
                idx += 1
              end
              resolved_value
            end
          end
        end

        def run_extensions_before_resolve(obj, args, ctx, extended, idx: 0)
          extension = @extensions[idx]
          if extension
            extension.resolve(object: obj, arguments: args, context: ctx) do |extended_obj, extended_args, memo|
              if memo
                memos = extended[:memos] ||= {}
                memos[idx] = memo
              end

              if (extras = extension.added_extras)
                ae = extended[:added_extras] ||= []
                ae.concat(extras)
              end

              extended[:obj] = extended_obj
              extended[:args] = extended_args
              run_extensions_before_resolve(extended_obj, extended_args, ctx, extended, idx: idx + 1) { |o, a| yield(o, a) }
            end
          else
            yield(obj, args)
          end
        end
      end
    end
  end
end
