# frozen_string_literal: true
module GraphQL
  class Schema
    class Implementation
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
              old_resolve.call(proxy, a, c)
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
            proxy_cls.new(obj, ctx)
          end
        end
      end
    end
  end
end
