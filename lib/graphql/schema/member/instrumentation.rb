# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module Instrumentation
        module_function
        def instrument(type, field)
          return_type = field.type.unwrap
          if (return_type.is_a?(GraphQL::ObjectType) && return_type.metadata[:type_class]) ||
              return_type.is_a?(GraphQL::InterfaceType) ||
              (return_type.is_a?(GraphQL::UnionType) && return_type.possible_types.any? { |t| t.metadata[:type_class] })
            field = apply_proxy(field)
          end

          field
        end

        def before_query(query)
          # Get the root type for this query
          root_node = query.irep_selection
          if root_node.nil?
            # It's an invalid query, nothing to do here
          else
            root_type = query.irep_selection.return_type
            # If it has a wrapper, apply it
            wrapper_class = root_type.metadata[:type_class]
            if wrapper_class
              new_root_value = wrapper_class.authorized_new(query.root_value, query.context)
              new_root_value = query.schema.sync_lazy(new_root_value)
              if new_root_value.nil?
                # This is definitely a hack,
                # but we need some way to tell execute.rb not to run.
                query.context[:__root_unauthorized] = true
              end
              query.root_value = new_root_value
            end
          end
        end

        def after_query(_query)
        end

        private

        module_function

        def apply_proxy(field)
          resolve_proc = field.resolve_proc
          lazy_resolve_proc = field.lazy_resolve_proc
          inner_return_type = field.type.unwrap
          depth = list_depth(field.type)

          field.redefine(
            resolve: ProxiedResolve.new(inner_resolve: resolve_proc, list_depth: depth, inner_return_type: inner_return_type),
            lazy_resolve: ProxiedResolve.new(inner_resolve: lazy_resolve_proc, list_depth: depth, inner_return_type: inner_return_type),
          )
        end

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

        class ProxiedResolve
          def initialize(inner_resolve:, list_depth:, inner_return_type:)
            @inner_resolve = inner_resolve
            @inner_return_type = inner_return_type
            @list_depth = list_depth
          end

          def call(obj, args, ctx)
            result = @inner_resolve.call(obj, args, ctx)
            if ctx.skip == result || ctx.schema.lazy?(result) || result.nil? || execution_errors?(result) || ctx.wrapped_object
              result
            else
              ctx.wrapped_object = true
              proxy_to_depth(result, @list_depth, ctx)
            end
          end

          private

          def execution_errors?(result)
            result.is_a?(GraphQL::ExecutionError) ||
              (result.is_a?(Array) && result.any? && result.all? { |v| v.is_a?(GraphQL::ExecutionError) })
          end

          def proxy_to_depth(inner_obj, depth, ctx)
            if depth > 0
              inner_obj.map { |i| proxy_to_depth(i, depth - 1, ctx) }
            else
              ctx.schema.after_lazy(inner_obj) do |inner_obj|
                if inner_obj.nil?
                  # For lists with nil, we need another nil check here
                  nil
                else
                  concrete_type_or_lazy = case @inner_return_type
                  when GraphQL::UnionType, GraphQL::InterfaceType
                    ctx.query.resolve_type(@inner_return_type, inner_obj)
                  when GraphQL::ObjectType
                    @inner_return_type
                  else
                    raise "unexpected proxying type #{@inner_return_type} for #{inner_obj} at #{ctx.owner_type}.#{ctx.field.name}"
                  end

                  # .resolve_type may have returned a lazy
                  ctx.schema.after_lazy(concrete_type_or_lazy) do |concrete_type|
                    if concrete_type && (object_class = concrete_type.metadata[:type_class])
                      # use the query-level context here, since it won't be field-specific anyways
                      query_ctx = ctx.query.context
                      object_class.authorized_new(inner_obj, query_ctx)
                    else
                      inner_obj
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
