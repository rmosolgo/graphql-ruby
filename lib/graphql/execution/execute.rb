module GraphQL
  module Execution
    # A valid execution strategy
    class Execute
      PROPAGATE_NULL = :__graphql_propagate_null__

      def execute(ast_operation, root_type, query)
        irep_root = query.internal_representation[ast_operation.name]

        result = resolve_selection(
          query.root_value,
          root_type,
          [irep_root],
          query.context,
          mutation: query.mutation?
        )

        GraphQL::Execution::Lazy.resolve(result)

        result.to_h
      end

      private

      def resolve_selection(object, current_type, irep_nodes, query_ctx, mutation: false )
        query = query_ctx.query
        own_selections = query.selections(irep_nodes, current_type)

        selection_result = SelectionResult.new

        own_selections.each do |name, child_irep_nodes|
          field = query.get_field(current_type, child_irep_nodes.first.definition_name)
          field_result = resolve_field(
            selection_result,
            child_irep_nodes,
            current_type,
            field,
            object,
            query_ctx
          )

          if mutation
            GraphQL::Execution::Lazy.resolve(field_result)
          end

          selection_result.set(name, field_result)
        end

        selection_result
      end

      def resolve_field(owner, irep_nodes, parent_type, field, object, query_ctx)
        irep_node = irep_nodes.first
        query = query_ctx.query
        field_ctx = query_ctx.spawn(
          parent_type: parent_type,
          field: field,
          key: irep_node.name,
          irep_node: irep_node,
          irep_nodes: irep_nodes,
        )

        arguments = query.arguments_for(irep_node, field)
        middlewares = query.schema.middleware
        resolve_arguments = [parent_type, object, field, arguments, field_ctx]

        raw_value = begin
          # only run a middleware chain if there are any middleware
          if middlewares.any?
            chain = GraphQL::Schema::MiddlewareChain.new(
              steps: middlewares + [FieldResolveStep],
              arguments: resolve_arguments
            )
            chain.call
          else
            FieldResolveStep.call(*resolve_arguments)
          end
        rescue GraphQL::ExecutionError => err
          err
        end

        lazy_method_name = query.lazy_method(raw_value)
        result = if lazy_method_name
          GraphQL::Execution::Lazy.new { raw_value.public_send(lazy_method_name) }.then { |inner_value|
            continue_resolve_field(irep_nodes, parent_type, field, inner_value, field_ctx)
          }
        else
          continue_resolve_field(irep_nodes, parent_type, field, raw_value, field_ctx)
        end

        FieldResult.new(
          owner: owner,
          field: field,
          value: result,
        )
      end

      def continue_resolve_field(irep_nodes, parent_type, field, raw_value, field_ctx)
        irep_node = irep_nodes.first
        query = field_ctx.query

        case raw_value
        when GraphQL::ExecutionError
          raw_value.ast_node = irep_node.ast_node
          raw_value.path = field_ctx.path
          query.context.errors.push(raw_value)
        when Array
          list_errors = raw_value.each_with_index.select { |value, _| value.is_a?(GraphQL::ExecutionError) }
          if list_errors.any?
            list_errors.each do |error, index|
              error.ast_node = irep_node.ast_node
              error.path = field_ctx.path + [index]
              query.context.errors.push(error)
            end
          end
        end

        resolve_value(
          parent_type,
          field,
          field.type,
          raw_value,
          irep_nodes,
          field_ctx,
        )
      end

      def resolve_value(parent_type, field_defn, field_type, value, irep_nodes, field_ctx)
        if value.nil?
          if field_type.kind.non_null?
            field_ctx.add_error(GraphQL::ExecutionError.new("Cannot return null for non-nullable field #{parent_type.name}.#{field_defn.name}"))
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
            field_type.coerce_result(value)
          when GraphQL::TypeKinds::ENUM
            field_type.coerce_result(value, field_ctx.query.warden)
          when GraphQL::TypeKinds::LIST
            wrapped_type = field_type.of_type
            result = value.each_with_index.map do |inner_value, index|
              inner_ctx = field_ctx.spawn(
                key: index,
                irep_node: field_ctx.irep_node,
                irep_nodes: irep_nodes,
                parent_type: parent_type,
                field: field_defn,
              )

              inner_result = resolve_value(
                parent_type,
                field_defn,
                wrapped_type,
                inner_value,
                irep_nodes,
                inner_ctx,
              )
              inner_result
            end
            result
          when GraphQL::TypeKinds::NON_NULL
            wrapped_type = field_type.of_type
            resolve_value(
              parent_type,
              field_defn,
              wrapped_type,
              value,
              irep_nodes,
              field_ctx,
            )
          when GraphQL::TypeKinds::OBJECT
            resolve_selection(
              value,
              field_type,
              irep_nodes,
              field_ctx
            )
          when GraphQL::TypeKinds::UNION, GraphQL::TypeKinds::INTERFACE
            query = field_ctx.query
            resolved_type = query.resolve_type(value)
            possible_types = query.possible_types(field_type)

            if !possible_types.include?(resolved_type)
              raise GraphQL::UnresolvedTypeError.new(irep_nodes.first.definition_name, field_type, parent_type, resolved_type, possible_types)
            else
              resolve_value(
                parent_type,
                field_defn,
                resolved_type,
                value,
                irep_nodes,
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
