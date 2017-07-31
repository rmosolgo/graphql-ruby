# frozen_string_literal: true
require "graphql/schema/implementation/method_call_implementation"
require "graphql/schema/implementation/public_send_implementation"
require "graphql/schema/implementation/type_missing"

module GraphQL
  class Schema
    # This is a batteries-included approach to GraphQL schema development.
    #
    # - Define some classes that correspond to types
    # - Define some methods that correspond to fields on that type
    #   - Or don't; the default is still method-send
    # - Write `.graphql` files
    # - Build a schema
    #   - Glob the `.graphql` files
    #   - Instantiate an `Implementation`
    #   - Pass them to a schema builder
    # - Validate that the implementation suits the schema
    #
    # There's going to have to be a proxy wrapper layer
    # so that we can instantiate one graphql object per application object.
    #
    class Implementation
      # @param namespace [Module]
      def initialize(namespace: Object)
        @namespace = namespace
        @schema = nil
        @fields = nil
        @scalars = nil
      end

      def set_schema(schema)
        schema.metadata[:implementation] = self
        @schema = schema
        @fields = build_fields(schema)
        proxy_map = @fields[:proxies]
        schema.instrument(:field, ApplyProxies.new(proxy_map))
        # validate
      end

      def call(type, field, obj, args, ctx)
        callable = @fields
          .fetch(type.name)
          .fetch(field.name)

        callable.call(obj, args, ctx)
      end

      def resolve_type(type, obj, ctx)
      end

      def coerce_input(type, value, ctx)
      end

      def coerce_result(type, value,ctx)
      end

      private

      # TODO can this be applied in initialization?
      class ApplyProxies
        def initialize(proxy_map)
          @proxy_map = proxy_map
        end

        def instrument(type, field)
          owner_type_name = type.name
          # TODO don't hardcode
          resolve_proc = if owner_type_name == "Query" || owner_type_name == "Mutation"
            old_resolve = field.resolve_proc
            ->(o, a, c) {
              proxy_cls = @proxy_map[owner_type_name]
              proxy = proxy_cls.new(o, c)
              proxied_object = ProxiedObject.new(o, proxy)
              old_resolve.call(proxied_object, a, c)
            }
          else
            field.resolve_proc
          end

          inner_return_type = field.type.unwrap
          resolve_proc_w_proxy = case inner_return_type
          when GraphQL::ObjectType, GraphQL::InterfaceType, GraphQL::UnionType
            depth = list_depth(field.type)
            ->(o, a, c) {
              result = resolve_proc.call(o, a, c)
              proxy_to_depth(result, depth, inner_return_type, @proxy_map, c)
            }
          else
            resolve_proc
          end

          field.redefine(resolve: resolve_proc_w_proxy)
        end

        private

        def list_depth(type, starting_at = 0)
          case type
          when GraphQL::ListType
            list_depth(type.of_type, starting_at + 1)
          when GraphQL::NonNullType
            list_depth(type.of_type, starting_at)
          else
            starting_at
          end
        end

        def proxy_to_depth(obj, depth, type, proxies, ctx)
          if depth > 0
            obj.map { |inner_obj| proxy_to_depth(inner_obj, depth - 1, type, proxies, ctx) }
          else
            concrete_type = type.resolve_type(obj, ctx)
            proxy_cls = proxies[concrete_type.name]
            proxy = proxy_cls.new(obj, ctx)
            ProxiedObject.new(obj, proxy)
          end
        end
      end

      class ProxiedObject
        attr_reader :object, :proxy
        def initialize(object, proxy)
          @object = object
          @proxy = proxy
        end
      end

      # TODO, can users extend this, provide custom args?
      SPECIAL_ARGS = Set.new([
        :context,
        :irep_node,
        :ast_node,
      ])

      def build_fields(schema)
        map = {
          proxies: {}
        }

        default_impl = if @namespace.const_defined?(:TypeMissing)
          @namespace.const_get(:TypeMissing)
        else
          Implementation::TypeMissing
        end

        schema.types.each do |name, type|
          if type.kind.fields?
            impl_constant_name = name.sub(/^__/, "Introspection::")
            impl_class = if @namespace.const_defined?(impl_constant_name)
              @namespace.const_get(impl_constant_name)
            else
              default_impl
            end
            map[:proxies][name] = impl_class
            fields = map[name] = {}

            type.all_fields.each do |field|
              field_name = field.name
              field_args = field.arguments
              # Remove camelization
              method_name = field_name
                .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
                .gsub(/([a-z\d])([A-Z])/,'\1_\2')
                .downcase

              fields[field.name] = if impl_class.method_defined?(method_name)
                field_method = impl_class.instance_method(method_name)
                graphql_args = []
                special_args = []
                # TODO assert required-ness matches between Ruby & GraphQL
                field_method.parameters.each do |(type, name)|
                  case type
                  when :req, :opt
                    raise "Positional arguments are not supported, see #{type_name}.#{method_name} (#{field_method.source_location})"
                  when :keyreq, :key
                    arg_name = name.to_s
                    if field_args.key?(arg_name)
                      graphql_args << name
                    elsif SPECIAL_ARGS.include?(name)
                      special_args << name
                    else
                      raise "#{type_name}.#{method_name}: Unexpected argument name #{name.inspect}, expected one of #{(field_args.keys + SPECIAL_ARGS).map(&:to_sym).map(&:inspect)} (#{field_method.source_location})"
                    end
                  end
                end

                Implementation::MethodCallImplementation.new(
                  method: method_name,
                  graphql_arguments: graphql_args,
                  special_arguments: special_args,
                )
              else
                Implementation::PublicSendImplementation.new(method: method_name)
              end
            end
          end
        end
        map
      end
    end
  end
end
