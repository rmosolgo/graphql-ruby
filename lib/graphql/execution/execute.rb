# frozen_string_literal: true
module GraphQL
  module Execution
    # A valid execution strategy
    # @api private
    class Execute
      PROPAGATE_NULL = :__graphql_propagate_null__

      def execute(ast_operation, root_type, query)
        result = resolve_selection(
          query.root_value,
          root_type,
          query.irep_selection,
          query.context,
          mutation: query.mutation?
        )

        GraphQL::Execution::Lazy.resolve(result)

        result.to_h
      end

      private

      def resolve_selection(object, current_type, selection, query_ctx, mutation: false )
        selection_result = SelectionResult.new

        selection.typed_children[current_type].each do |name, subselection|
          field_result = resolve_field(
            selection_result,
            subselection,
            current_type,
            subselection.definition,
            object,
            query_ctx
          )

          if mutation
            GraphQL::Execution::Lazy.resolve(field_result)
          end

          selection_result.set(name, field_result)

          # If the last subselection caused a null to propagate to _this_ selection,
          # then we may as well quit executing fields because they
          # won't be in the response
          if selection_result.invalid_null?
            break
          end
        end

        selection_result
      end

      def resolve_field(owner, selection, parent_type, field, object, query_ctx)
        query = query_ctx.query
        field_ctx = query_ctx.spawn(
          parent_type: parent_type,
          field: field,
          key: selection.name,
          selection: selection,
        )

        arguments = query.arguments_for(selection, field)
        raw_value = begin
          query_ctx.schema.middleware.invoke([parent_type, object, field, arguments, field_ctx])
        rescue GraphQL::ExecutionError => err
          err
        end

        result = if query.schema.lazy?(raw_value)
          field.prepare_lazy(raw_value, arguments, field_ctx).then { |inner_value|
            continue_resolve_field(owner, selection, parent_type, field, inner_value, field_ctx)
          }
        elsif raw_value.is_a?(GraphQL::Execution::Lazy)
          # It came from a connection resolve, assume it was already instrumented
          raw_value.then { |inner_value|
            continue_resolve_field(owner, selection, parent_type, field, inner_value, field_ctx)
          }
        else
          continue_resolve_field(owner, selection, parent_type, field, raw_value, field_ctx)
        end

        case result
        when PROPAGATE_NULL, GraphQL::Execution::Lazy, SelectionResult
          FieldResult.new(
            owner: owner,
            type: field.type,
            value: result,
          )
        else
          result
        end
      end

      def continue_resolve_field(owner, selection, parent_type, field, raw_value, field_ctx)
        query = field_ctx.query

        case raw_value
        when GraphQL::ExecutionError
          raw_value.ast_node = field_ctx.ast_node
          raw_value.path = field_ctx.path
          query.context.errors.push(raw_value)
        when Array
          list_errors = raw_value.each_with_index.select { |value, _| value.is_a?(GraphQL::ExecutionError) }
          if list_errors.any?
            list_errors.each do |error, index|
              error.ast_node = field_ctx.ast_node
              error.path = field_ctx.path + [index]
              query.context.errors.push(error)
            end
          end
        end

        resolve_value(
          owner,
          parent_type,
          field,
          field.type,
          raw_value,
          selection,
          field_ctx,
        )
      end

      def resolve_value(owner, parent_type, field_defn, field_type, value, selection, field_ctx)
        if value.nil?
          if field_type.kind.non_null?
            type_error = GraphQL::InvalidNullError.new(parent_type, field_defn, value)
            field_ctx.schema.type_error(type_error, field_ctx)
            PROPAGATE_NULL
          else
            nil
          end
        elsif value.is_a?(GraphQL::ExecutionError)
          if field_type.kind.non_null?
            PROPAGATE_NULL
          else
            nil
          end
        else
          case field_type.kind
          when GraphQL::TypeKinds::SCALAR
            field_type.coerce_result(value, field_ctx)
          when GraphQL::TypeKinds::ENUM
            field_type.coerce_result(value, field_ctx)
          when GraphQL::TypeKinds::LIST
            inner_type = field_type.of_type
            i = 0
            result = []
            value.each do |inner_value|
              inner_ctx = field_ctx.spawn(
                key: i,
                selection: selection,
                parent_type: parent_type,
                field: field_defn,
              )

              inner_result = resolve_value(
                owner,
                parent_type,
                field_defn,
                inner_type,
                inner_value,
                selection,
                inner_ctx,
              )

              result << GraphQL::Execution::FieldResult.new(type: inner_type, owner: owner, value: inner_result)
              i += 1
            end
            result
          when GraphQL::TypeKinds::NON_NULL
            wrapped_type = field_type.of_type
            resolve_value(
              owner,
              parent_type,
              field_defn,
              wrapped_type,
              value,
              selection,
              field_ctx,
            )
          when GraphQL::TypeKinds::OBJECT
            resolve_selection(
              value,
              field_type,
              selection,
              field_ctx
            )
          when GraphQL::TypeKinds::UNION, GraphQL::TypeKinds::INTERFACE
            query = field_ctx.query
            resolved_type = query.resolve_type(value)
            possible_types = query.possible_types(field_type)

            if !possible_types.include?(resolved_type)
              type_error = GraphQL::UnresolvedTypeError.new(value, field_defn, parent_type, resolved_type, possible_types)
              field_ctx.schema.type_error(type_error, field_ctx)
              PROPAGATE_NULL
            else
              resolve_value(
                owner,
                parent_type,
                field_defn,
                resolved_type,
                value,
                selection,
                field_ctx,
              )
            end
          else
            raise("Unknown type kind: #{field_type.kind}")
          end
        end
      end

      # A `.call`-able suitable to be the last step in a middleware chain
      module FieldResolveStep
        # Execute the field's resolve method
        def self.call(_parent_type, parent_object, field_definition, field_args, context, _next = nil)
          field_definition.resolve(parent_object, field_args, context)
        end
      end
    end
  end
end
