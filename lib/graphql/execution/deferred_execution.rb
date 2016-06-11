module GraphQL
  module Execution
    # A query execution strategy that emits
    # `{ path: [...], value: ... }` patches as it
    # resolves the query.
    #
    # @example Using DeferredExecution for your schema
    #   MySchema.query_execution_strategy = GraphQL::Execution::DeferredExecution
    #
    # @example A "collector" class which accepts patches and forwards them
    #   # Take patches from GraphQL and forward them to clients over a websocket.
    #   # (This is pseudo-code, I don't know a websocket library that works this way.)
    #   class WebsocketCollector
    #     # Accept `query_id` from the client, which allows the
    #     # client to identify patches as they come in.
    #     def initialize(query_id, websocket_conn)
    #       @query_id = query_id
    #       @websocket_conn = websocket_conn
    #     end
    #
    #     # Accept a patch from GraphQL and send it to the client.
    #     # Include `query_id` so that the client knows which
    #     # response to merge this patch into.
    #     def patch(path:, value:)
    #       @websocket_conn.send({
    #          query_id: @query_id,
    #          path: path,
    #          value: value,
    #       })
    #     end
    #   end
    #
    # @example Executing a query with a collector
    #   collector = WebsocketCollector.new(params[:query_id], websocket_conn)
    #   query_ctx = {collector: collector, current_user: current_user}
    #   MySchema.execute(query_string, variables: variables, context: query_ctx)
    #   # Ignore the return value -- it will be emitted via `WebsocketCollector#patch`
    #
    # @example Executing a query WITHOUT a collector
    #   query_ctx = {collector: nil, current_user: current_user}
    #   result = MySchema.execute(query_string, variables: variables, context: query_ctx)
    #   # `result` contains any non-deferred fields
    #   render json: result
    #
    class DeferredExecution
      include GraphQL::Language
      # This key in context will be used to send patches.
      CONTEXT_PATCH_TARGET = :collector

      # Returned by {.resolve_or_defer_frame} to signal that the frame's
      # result was defered, so it should be empty in the patch.
      DEFERRED_RESULT = :__deferred_result__

      # Execute `ast_operation`, a member of `query_object`, starting from `root_type`.
      #
      # Results will be sent to `query_object.context[CONTEXT_PATCH_TARGET]` in the form
      # of `#patch(path, value)`.
      #
      # If the patch target is absent, no patches will be sent.
      #
      # This method always returns the initial result
      # and shoves any inital errors in to `query_object.context.errors`.
      # For queries with no defers, you can leave out a patch target and simply
      # use the return value.
      #
      # @return [Object] the initial result, without any defers
      def execute(ast_operation, root_type, query_object)
        collector = query_object.context[CONTEXT_PATCH_TARGET]
        irep_root = query_object.internal_representation[ast_operation.name]

        scope = ExecScope.new(query_object)
        initial_thread = ExecThread.new
        initial_frame = ExecFrame.new(
          node: irep_root,
          value: query_object.root_value,
          type: irep_root.return_type,
          path: []
        )

        initial_result = resolve_or_defer_frame(scope, initial_thread, initial_frame)

        if collector
          initial_data = if initial_result == DEFERRED_RESULT
            {}
          else
            initial_result
          end
          initial_patch = {"data" => initial_data}

          initial_errors = initial_thread.errors + query_object.context.errors
          error_idx = initial_errors.length

          if initial_errors.any?
            initial_patch["errors"] = initial_errors.map(&:to_h)
          end

          collector.patch(
            path: [],
            value: initial_patch
          )

          defers = initial_thread.defers
          while defers.any?
            next_defers = []
            defers.each do |deferral|
              deferred_thread = ExecThread.new
              case deferral
              when ExecFrame
                deferred_frame = deferral
                deferred_result = resolve_frame(scope, deferred_thread, deferred_frame)

              when ExecStream
                begin
                  list_frame = deferral.frame
                  inner_type = deferral.type
                  item, idx = deferral.enumerator.next
                  deferred_frame = ExecFrame.new({
                    node: list_frame.node,
                    path: list_frame.path + [idx],
                    type: inner_type,
                    value: item,
                  })
                  deferred_result = resolve_value(scope, deferred_thread, deferred_frame, item, inner_type)
                  deferred_thread.defers << deferral
                rescue StopIteration
                  # The enum is done
                end
              else
                raise("Can't continue deferred #{deferred_frame.class.name}")
              end

              # TODO: Should I patch nil?
              if !deferred_result.nil?
                collector.patch(
                  path: ["data"] + deferred_frame.path,
                  value: deferred_result
                )
              end

              deferred_thread.errors.each do |deferred_error|
                collector.patch(
                  path: ["errors", error_idx],
                  value: deferred_error.to_h
                )
                error_idx += 1
              end
              next_defers.push(*deferred_thread.defers)
            end
            defers = next_defers
          end
        else
          query_object.context.errors.push(*initial_thread.errors)
        end

        initial_result
      end

      # Global, immutable environment for executing `query`.
      # Passed through all execution to provide type, fragment and field lookup.
      class ExecScope
        attr_reader :query, :schema

        def initialize(query)
          @query = query
          @schema = query.schema
        end

        def get_type(type)
          @schema.types[type]
        end

        def get_fragment(name)
          @query.fragments[name]
        end

        # This includes dynamic fields like __typename
        def get_field(type, name)
          @schema.get_field(type, name) || raise("No field named '#{name}' found for #{type}")
        end
      end

      # One serial stream of execution. One thread runs the initial query,
      # then any deferred frames are restarted with their own threads.
      #
      # - {ExecThread#errors} contains errors during this part of the query
      # - {ExecThread#defers} contains {ExecFrame}s which were marked as `@defer`
      #   and will be executed with their own threads later.
      class ExecThread
        attr_reader :errors, :defers
        def initialize
          @errors = []
          @defers = []
        end
      end

      # One step of execution. Each step in execution gets its own frame.
      #
      # - {ExecFrame#node} is the IRep node which is being interpreted
      # - {ExecFrame#path} is like a stack trace, it is used for patching deferred values
      # - {ExecFrame#value} is the object being exposed by GraphQL at this point
      # - {ExecFrame#type} is the GraphQL type which exposes {#value} at this point
      class ExecFrame
        attr_reader :node, :path, :type, :value
        def initialize(node:, path:, type:, value:)
          @node = node
          @path = path
          @type = type
          @value = value
        end
      end

      # Contains the list field's ExecFrame
      # And the enumerator which is being mapped
      # - {ExecStream#enumerator} is an Enumerator which yields `item, idx`
      # - {ExecStream#frame} is the {ExecFrame} for the list selection (where `@stream` was present)
      # - {ExecStream#type} is the inner type of the list (the item's type)
      class ExecStream
        attr_reader :enumerator, :frame, :type
        def initialize(enumerator:, frame:, type:)
          @enumerator = enumerator
          @frame = frame
          @type = type
        end
      end

      private

      # If this `frame` is marked as defer, add it to `defers`
      # and return {DEFERRED_RESULT}
      # Otherwise, resolve it and return its value.
      def resolve_or_defer_frame(scope, thread, frame)
        if GraphQL::Execution::DirectiveChecks.defer?(frame.node)
          thread.defers << frame
          DEFERRED_RESULT
        else
          resolve_frame(scope, thread, frame)
        end
      end

      # Determine this frame's result and return it
      # Any subselections marked as `@defer` will be deferred.
      def resolve_frame(scope, thread, frame)
        ast_node = frame.node.ast_node
        case ast_node
        when Nodes::OperationDefinition
          resolve_selections(scope, thread, frame)
        when Nodes::Field
          type_defn = frame.type
          field_defn = scope.get_field(type_defn, frame.node.definition_name)
          field_result = resolve_field_frame(scope, thread, frame, field_defn)
          return_type_defn = field_defn.type

          resolve_value(
            scope,
            thread,
            frame,
            field_result,
            return_type_defn,
          )
        else
          raise("No defined resolution for #{ast_node.class.name} (#{ast_node})")
        end
      rescue GraphQL::InvalidNullError => err
        if return_type_defn && return_type_defn.kind.non_null?
          raise(err)
        else
          err.parent_error? || thread.errors << err
          nil
        end
      end

      # Recursively resolve selections on `outer_frame.node`.
      # Return a `Hash<String, Any>` of identifiers and results.
      # Deferred fields will be absent from the result.
      def resolve_selections(scope, thread, outer_frame)
        merged_selections = outer_frame.node.children
        query = scope.query

        resolved_selections = merged_selections.each_with_object({}) do |(name, irep_selection), memo|
          field_applies_to_type = irep_selection.definitions.any? do |child_type, defn|
            GraphQL::Execution::Typecast.compatible?(outer_frame.value, child_type, outer_frame.type, query.context)
          end
          if field_applies_to_type && !GraphQL::Execution::DirectiveChecks.skip?(irep_selection, query)
            selection_key = irep_selection.name

            inner_frame = ExecFrame.new(
              node: irep_selection,
              path: outer_frame.path + [selection_key],
              type: outer_frame.type,
              value: outer_frame.value,
            )

            inner_result = resolve_or_defer_frame(scope, thread, inner_frame)
            if inner_result != DEFERRED_RESULT
              memo[selection_key] = inner_result
            end
          end
        end
        resolved_selections
      end

      # Resolve `field_defn` on `frame.node`, returning the value
      # of the {Field#resolve} proc.
      # It might be an error or an object, not ready for serialization yet.
      # @return [Object] the return value from `field_defn`'s resolve proc
      def resolve_field_frame(scope, thread, frame, field_defn)
        ast_node = frame.node.ast_node
        type_defn = frame.type
        value = frame.value
        query = scope.query

        # Build arguments according to query-string literals, default values, and query variables
        arguments = query.arguments_for(frame.node, field_defn)

        # This is the last call in the middleware chain; it actually calls the user's resolve proc
        field_resolve_middleware_proc = -> (_parent_type, parent_object, field_definition, field_args, query_ctx, _next) {
          query_ctx.ast_node = ast_node
          query_ctx.irep_node = frame.node
          value = field_definition.resolve(parent_object, field_args, query_ctx)
          query_ctx.ast_node = nil
          query_ctx.irep_node = frame.node
          value
        }

        # Send arguments through the middleware stack,
        # ending with the field resolve call
        steps = query.schema.middleware + [field_resolve_middleware_proc]
        chain = GraphQL::Schema::MiddlewareChain.new(
          steps: steps,
          arguments: [type_defn, value, field_defn, arguments, query.context]
        )

        begin
          resolve_fn_value = chain.call
        rescue GraphQL::ExecutionError => err
          resolve_fn_value = err
        end

        if resolve_fn_value.is_a?(GraphQL::ExecutionError)
          thread.errors << resolve_fn_value
          resolve_fn_value.ast_node = ast_node
        end

        resolve_fn_value
      end

      # Recursively finish `value` which was returned from `frame`,
      # expected to be an instance of `type_defn`.
      # This coerces terminals and recursively resolves non-terminals (object, list, non-null).
      # @return [Object] the response-ready version of `value`
      def resolve_value(scope, thread, frame, value, type_defn)
        if value.nil? || value.is_a?(GraphQL::ExecutionError)
          if type_defn.kind.non_null?
            raise GraphQL::InvalidNullError.new(frame.node.ast_node.name, value)
          else
            nil
          end
        else
          case type_defn.kind
          when GraphQL::TypeKinds::SCALAR, GraphQL::TypeKinds::ENUM
            type_defn.coerce_result(value)
          when GraphQL::TypeKinds::INTERFACE, GraphQL::TypeKinds::UNION
            resolved_type = type_defn.resolve_type(value, scope)

            if !resolved_type.is_a?(GraphQL::ObjectType)
              raise GraphQL::ObjectType::UnresolvedTypeError.new(frame.node.definition_name, type_defn, frame.node.parent.return_type)
            else
              resolve_value(scope, thread, frame, value, resolved_type)
            end
          when GraphQL::TypeKinds::NON_NULL
            wrapped_type = type_defn.of_type
            resolve_value(scope, thread, frame, value, wrapped_type)
          when GraphQL::TypeKinds::LIST
            wrapped_type = type_defn.of_type
            items_enumerator = value.map.with_index
            if GraphQL::Execution::DirectiveChecks.stream?(frame.node)
              thread.defers << ExecStream.new(
                enumerator: items_enumerator,
                frame: frame,
                type: wrapped_type,
              )
              # The streamed list is empty in the initial resolve:
              []
            else
              resolved_values = items_enumerator.each do |item, idx|
                inner_frame = ExecFrame.new({
                  node: frame.node,
                  path: frame.path + [idx],
                  type: wrapped_type,
                  value: item,
                })
                resolve_value(scope, thread, inner_frame, item, wrapped_type)
              end
              resolved_values
            end
          when GraphQL::TypeKinds::OBJECT
            inner_frame = ExecFrame.new(
              node: frame.node,
              path: frame.path,
              value: value,
              type: type_defn,
            )
            resolve_selections(scope, thread, inner_frame)
          else
            raise("No ResolveValue for kind: #{type_defn.kind.name} (#{type_defn})")
          end
        end
      end
    end
  end
end
