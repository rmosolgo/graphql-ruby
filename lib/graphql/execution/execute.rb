# frozen_string_literal: true
module GraphQL
  module Execution
    # A valid execution strategy
    # @api private
    class Execute

      # @api private
      class Skip; end

      # Just a singleton for implementing {Query::Context#skip}
      # @api private
      SKIP = Skip.new

      # @api private
      class PropagateNull
      end
      # @api private
      PROPAGATE_NULL = PropagateNull.new

      def self.use(schema_class)
        schema_class.query_execution_strategy(self)
        schema_class.mutation_execution_strategy(self)
        schema_class.subscription_execution_strategy(self)
      end

      def execute(ast_operation, root_type, query)
        GraphQL::Deprecation.warn "#{self.class} will be removed in GraphQL-Ruby 2.0, please upgrade to the Interpreter: https://graphql-ruby.org/queries/interpreter.html"
        result = resolve_root_selection(query)
        lazy_resolve_root_selection(result, **{query: query})
        GraphQL::Execution::Flatten.call(query.context)
      end

      def self.begin_multiplex(_multiplex)
      end

      def self.begin_query(query, _multiplex)
        ExecutionFunctions.resolve_root_selection(query)
      end

      def self.finish_multiplex(results, multiplex)
        ExecutionFunctions.lazy_resolve_root_selection(results, multiplex: multiplex)
      end

      def self.finish_query(query, _multiplex)
        {
          "data" => Execution::Flatten.call(query.context)
        }
      end

      # @api private
      module ExecutionFunctions
        module_function

        def resolve_root_selection(query)
          query.trace("execute_query", query: query) do
            operation = query.selected_operation
            op_type = operation.operation_type
            root_type = query.root_type_for_operation(op_type)
            if query.context[:__root_unauthorized]
              # This was set by member/instrumentation.rb so that we wouldn't continue.
            else
              resolve_selection(
                query.root_value,
                root_type,
                query.context,
                mutation: query.mutation?
              )
            end
          end
        end

        def lazy_resolve_root_selection(result, query: nil, multiplex: nil)
          if query.nil? && multiplex.queries.length == 1
            query = multiplex.queries[0]
          end

          tracer = (query || multiplex)
          tracer.trace("execute_query_lazy", {multiplex: multiplex, query: query}) do
            GraphQL::Execution::Lazy.resolve(result)
          end
        end

        def resolve_selection(object, current_type, current_ctx, mutation: false )
          # Assign this _before_ resolving the children
          # so that when a child propagates null, the selection result is
          # ready for it.
          current_ctx.value = {}

          selections_on_type = current_ctx.irep_node.typed_children[current_type]

          selections_on_type.each do |name, child_irep_node|
            field_ctx = current_ctx.spawn_child(
              key: name,
              object: object,
              irep_node: child_irep_node,
            )

            field_result = resolve_field(
              object,
              field_ctx
            )

            if field_result.is_a?(Skip)
              next
            end

            if mutation
              GraphQL::Execution::Lazy.resolve(field_ctx)
            end


            # If the last subselection caused a null to propagate to _this_ selection,
            # then we may as well quit executing fields because they
            # won't be in the response
            if current_ctx.invalid_null?
              break
            else
              current_ctx.value[name] = field_ctx
            end
          end

          current_ctx.value
        end

        def resolve_field(object, field_ctx)
          query = field_ctx.query
          irep_node = field_ctx.irep_node
          parent_type = irep_node.owner_type
          field = field_ctx.field

          raw_value = begin
            begin
              arguments = query.arguments_for(irep_node, field)
              field_ctx.trace("execute_field", { context: field_ctx }) do
                field_ctx.schema.middleware.invoke([parent_type, object, field, arguments, field_ctx])
              end
            rescue GraphQL::UnauthorizedFieldError => err
              err.field ||= field
              field_ctx.schema.unauthorized_field(err)
            rescue GraphQL::UnauthorizedError => err
              field_ctx.schema.unauthorized_object(err)
            end
          rescue GraphQL::ExecutionError => err
            err
          end

          if field_ctx.schema.lazy?(raw_value)
            field_ctx.value = Execution::Lazy.new {
              inner_value = field_ctx.trace("execute_field_lazy", {context: field_ctx}) {
                begin
                  begin
                    field_ctx.field.lazy_resolve(raw_value, arguments, field_ctx)
                  rescue GraphQL::UnauthorizedError => err
                    field_ctx.schema.unauthorized_object(err)
                  end
                rescue GraphQL::ExecutionError => err
                  err
                end
              }
              continue_or_wait(inner_value, field_ctx.type, field_ctx)
            }
          else
            continue_or_wait(raw_value, field_ctx.type, field_ctx)
          end
        end

        # If the returned object is lazy (unfinished),
        # assign the lazy object to `.value=` so we can resolve it later.
        # When we resolve it later, reassign it to `.value=` so that
        # the finished value replaces the unfinished one.
        #
        # If the returned object is finished, continue to coerce
        # and resolve child fields
        def continue_or_wait(raw_value, field_type, field_ctx)
          if field_ctx.schema.lazy?(raw_value)
            field_ctx.value = Execution::Lazy.new {
              inner_value = begin
                  begin
                    field_ctx.schema.sync_lazy(raw_value)
                  rescue GraphQL::UnauthorizedError => err
                    field_ctx.schema.unauthorized_object(err)
                  end
                rescue GraphQL::ExecutionError => err
                  err
                end

              field_ctx.value = continue_or_wait(inner_value, field_type, field_ctx)
            }
          else
            field_ctx.value = continue_resolve_field(raw_value, field_type, field_ctx)
          end
        end

        def continue_resolve_field(raw_value, field_type, field_ctx)
          if field_ctx.parent.invalid_null?
            return nil
          end
          query = field_ctx.query

          case raw_value
          when GraphQL::ExecutionError
            raw_value.ast_node ||= field_ctx.ast_node
            raw_value.path = field_ctx.path
            query.context.errors.push(raw_value)
          when Array
            if field_type.non_null?
              # List type errors are handled above, this is for the case of fields returning an array of errors
              list_errors = raw_value.each_with_index.select { |value, _| value.is_a?(GraphQL::ExecutionError) }
              if list_errors.any?
                list_errors.each do |error, index|
                  error.ast_node = field_ctx.ast_node
                  error.path = field_ctx.path + (field_ctx.type.list? ? [index] : [])
                  query.context.errors.push(error)
                end
              end
            end
          end

          resolve_value(
            raw_value,
            field_type,
            field_ctx,
          )
        end

        def resolve_value(value, field_type, field_ctx)
          field_defn = field_ctx.field

          if value.nil?
            if field_type.kind.non_null?
              parent_type = field_ctx.irep_node.owner_type
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
          elsif value.is_a?(Array) && value.any? && value.all? {|v| v.is_a?(GraphQL::ExecutionError)}
            if field_type.kind.non_null?
              PROPAGATE_NULL
            else
              nil
            end
          elsif value.is_a?(Skip)
            field_ctx.value = value
          else
            case field_type.kind
            when GraphQL::TypeKinds::SCALAR, GraphQL::TypeKinds::ENUM
              field_type.coerce_result(value, field_ctx)
            when GraphQL::TypeKinds::LIST
              inner_type = field_type.of_type
              i = 0
              result = []
              field_ctx.value = result

              value.each do |inner_value|
                inner_ctx = field_ctx.spawn_child(
                  key: i,
                  object: inner_value,
                  irep_node: field_ctx.irep_node,
                )

                inner_result = continue_or_wait(
                  inner_value,
                  inner_type,
                  inner_ctx,
                )

                return PROPAGATE_NULL if inner_result == PROPAGATE_NULL

                result << inner_ctx
                i += 1
              end

              result
            when GraphQL::TypeKinds::NON_NULL
              inner_type = field_type.of_type
              resolve_value(
                value,
                inner_type,
                field_ctx,
              )
            when GraphQL::TypeKinds::OBJECT
              resolve_selection(
                value,
                field_type,
                field_ctx
              )
            when GraphQL::TypeKinds::UNION, GraphQL::TypeKinds::INTERFACE
              query = field_ctx.query
              resolved_type_or_lazy = field_type.resolve_type(value, field_ctx)
              query.schema.after_lazy(resolved_type_or_lazy) do |resolved_type|
                possible_types = query.possible_types(field_type)

                if !possible_types.include?(resolved_type)
                  parent_type = field_ctx.irep_node.owner_type
                  type_error = GraphQL::UnresolvedTypeError.new(value, field_defn, parent_type, resolved_type, possible_types)
                  field_ctx.schema.type_error(type_error, field_ctx)
                  PROPAGATE_NULL
                else
                  resolve_value(
                    value,
                    resolved_type,
                    field_ctx,
                  )
                end
              end
            else
              raise("Unknown type kind: #{field_type.kind}")
            end
          end
        end
      end

      include ExecutionFunctions

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
