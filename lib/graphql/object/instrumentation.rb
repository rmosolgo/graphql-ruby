# frozen_string_literal: true
# test_via: ../object.rb

module GraphQL
  class Object < GraphQL::SchemaMember
    # TODO use objects, not proc literals
    module Instrumentation
      module_function
      def instrument(type, field)
        return_type = field.type.unwrap
        # TODO this is too grabby, we can skip some union types
        if return_type.metadata[:object_class] || return_type.is_a?(GraphQL::UnionType) || return_type.is_a?(GraphQL::InterfaceType)
          field = apply_proxy(field)
        end

        if type.metadata[:object_class] && (type.name == "Query" || type.name == "Mutation" || type.name == "Subscription")
          # TODO don't hardcode the names above somehow
          # TODO: this makes a new proxy for each hit to a root field, which we don't want to do.
          # This proxying shuould be somewhere else, like in `GraphQL::Query#initialize`
          field = apply_pre_proxy(type, field)
        end

        field
      end


      private

      module_function

      def apply_proxy(field)
        resolve_proc = field.resolve_proc
        lazy_resolve_proc = field.lazy_resolve_proc
        inner_return_type = field.type.unwrap
        depth = list_depth(field.type)
        resolve_proc_w_proxy = ->(o, a, c) {
          result = resolve_proc.call(o, a, c)
          if c.schema.lazy?(result)
            # Wrap it later
            result
          else
            proxy_to_depth(result, depth, inner_return_type, c)
          end
        }
        lazy_resolve_proc_w_proxy = ->(o, a, c) {
          result = lazy_resolve_proc.call(o, a, c)
          if c.schema.lazy?(result)
            # Wrap it later
            result
          else
            proxy_to_depth(result, depth, inner_return_type, c)
          end
        }
        field.redefine(resolve: resolve_proc_w_proxy, lazy_resolve: lazy_resolve_proc_w_proxy)
      end

      def apply_pre_proxy(type, field)
        resolve_proc = field.resolve_proc
        resolve_proc_w_proxy = ->(o, a, c) {
          proxied_obj = type.metadata[:object_class].new(o, c)
          resolve_proc.call(proxied_obj, a, c)
        }
        field.redefine(resolve: resolve_proc_w_proxy)
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

      def proxy_to_depth(obj, depth, type, ctx)
        if depth > 0
          obj.map { |inner_obj| proxy_to_depth(inner_obj, depth - 1, type, ctx) }
        elsif obj.nil?
          obj
        else
          # TODO `resolve_type` should handle this without raising
          # NoMethodError: undefined method `resolve_type_proc' for Project:GraphQL::ObjectType
          #  /Users/rmosolgo/github/github/vendor/gems/2.4.0/ruby/2.4.0/gems/graphql-1.6.7/lib/graphql/schema.rb:354:in `resolve_type'
          #  /Users/rmosolgo/github/github/vendor/gems/2.4.0/ruby/2.4.0/gems/graphql-1.6.7/lib/graphql/query.rb:84:in `block (2 levels) in initialize'
          #  /Users/rmosolgo/github/github/vendor/gems/2.4.0/ruby/2.4.0/gems/graphql-1.6.7/lib/graphql/query.rb:206:in `resolve_type'
          concrete_type = case type
          when GraphQL::UnionType, GraphQL::InterfaceType
            ctx.query.resolve_type(type, obj)
          when GraphQL::ObjectType
            type
          else
            raise "unexpected proxying type #{type} for #{obj} at #{ctx.owner_type}.#{ctx.field.name}"
          end

          if concrete_type && (object_class = concrete_type.metadata[:object_class])
            object_class.new(obj, ctx)
          else
            obj
          end
        end
      end
    end
  end
end
