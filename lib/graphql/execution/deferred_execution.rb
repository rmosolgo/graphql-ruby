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

      # TODO: this is necessary to send the error to a context where
      # the parent type name is available
      class InnerInvalidNullError < GraphQL::Error
        attr_reader :field_name, :value
        def initialize(field_name, value)
          @field_name = field_name
          @value = value
        end
      end

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
        collector = query_object.context[CONTEXT_PATCH_TARGET] || MergeCollector.new
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
        resolve_batches(scope, initial_thread, query_object, initial_result)

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
              if deferred_result.is_a?(GraphQL::Execution::Batch::BatchResolve)
                # TODO: this will miss nested resolves
                res = {}
                resolve_batches(scope, deferred_thread, query_object, res)
                deferred_result = get_in(res, deferred_frame.path)
              end
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
                field_defn = scope.get_field(list_frame.type, list_frame.node.definition_name)
                deferred_result = resolve_value(scope, deferred_thread, deferred_frame, item, field_defn, inner_type)

                # TODO: deep merge ??
                res = {}
                resolve_batches(scope, deferred_thread, query_object, res)
                if res.any?
                  deferred_result = get_in(res, deferred_frame.path)
                end

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
                path: ["data"].concat(deferred_frame.path),
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

        initial_data
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
            field_defn,
            return_type_defn,
          )
        else
          raise("No defined resolution for #{ast_node.class.name} (#{ast_node})")
        end
      rescue InvalidNullError, InnerInvalidNullError => inner_err
        # TODO omg
        err = if inner_err.is_a?(InnerInvalidNullError)
          GraphQL::InvalidNullError.new(type_defn.name, inner_err.field_name, inner_err.value)
        else
          inner_err
        end

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
        query = scope.query
        selection_result = {}

        outer_frame.node.typed_children.each do |type_cond, children|
          if GraphQL::Execution::Typecast.compatible?(outer_frame.type, type_cond, query.context)
            children.each do |selection_name, irep_node|
              if irep_node.included?
                previous_result = selection_result.fetch(selection_name, :__graphql_not_resolved__)

                case previous_result
                when :__graphql_not_resolved__, Hash
                  # There's no value for this yet, so we can assign it directly
                  # OR
                  # This field was also requested on a different type, so we need
                  # to deeply merge _this_ branch with the other branch

                  inner_frame = ExecFrame.new(
                    node: irep_node,
                    path: outer_frame.path + [selection_name],
                    type: outer_frame.type,
                    value: outer_frame.value,
                  )

                  inner_result = resolve_or_defer_frame(scope, thread, inner_frame)
                else
                  # This value has already been resolved in another type branch
                end

                if inner_result == DEFERRED_RESULT || inner_result.is_a?(GraphQL::Execution::Batch::BatchResolve)
                  # This result was dealt with by the thread
                else
                  GraphQL::Execution::MergeBranchResult.merge(selection_result, { selection_name => inner_result })
                end
              end
            end
          end
        end

        selection_result
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

        query.context.irep_node = frame.node

        # This is the last call in the middleware chain; it actually calls the user's resolve proc
        field_resolve_middleware_proc = -> (_parent_type, parent_object, field_definition, field_args, query_ctx, _next) {
          field_definition.resolve(parent_object, field_args, query_ctx)
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

        query.context.irep_node = nil

        case resolve_fn_value
        when GraphQL::ExecutionError
          thread.errors << resolve_fn_value
          resolve_fn_value.ast_node = ast_node
          resolve_fn_value.path = frame.path
        when Array
          resolve_fn_value.each_with_index do |item, idx|
            if item.is_a?(GraphQL::ExecutionError)
              item.ast_node = ast_node
              item.path = frame.path + [idx]
              thread.errors << item
            end
          end
        end

        resolve_fn_value
      end

      # Recursively finish `value` which was returned from `frame`,
      # expected to be an instance of `type_defn`.
      # This coerces terminals and recursively resolves non-terminals (object, list, non-null).
      # @return [Object] the response-ready version of `value`
      def resolve_value(scope, thread, frame, value, field_defn, type_defn)
        case value
        when nil, GraphQL::ExecutionError
          if type_defn.kind.non_null?
            raise InnerInvalidNullError.new(frame.node.ast_node.name, value)
          else
            nil
          end
        when GraphQL::Execution::Batch::BatchResolve
          scope.query.accumulator.register(
            field_defn.batch_loader.func,
            field_defn.batch_loader.args,
            frame,
            value
          )
          value
        else
          case type_defn.kind
          when GraphQL::TypeKinds::SCALAR, GraphQL::TypeKinds::ENUM
            type_defn.coerce_result(value)
          when GraphQL::TypeKinds::INTERFACE, GraphQL::TypeKinds::UNION
            resolved_type = scope.schema.resolve_type(value, scope.query.context)

            possible_types = scope.schema.possible_types(type_defn)
            if !resolved_type.is_a?(GraphQL::ObjectType) || !possible_types.include?(resolved_type)
              raise GraphQL::UnresolvedTypeError.new(frame.node.definition_name, type_defn, frame.node.parent.return_type, resolved_type, possible_types)
            else
              resolve_value(scope, thread, frame, value, field_defn, resolved_type)
            end
          when GraphQL::TypeKinds::NON_NULL
            wrapped_type = type_defn.of_type
            resolve_value(scope, thread, frame, value, field_defn, wrapped_type)
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
                resolve_value(scope, thread, inner_frame, item, field_defn, wrapped_type)
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

      def set_in(data, path, value)
        path = path.dup
        last = path.pop
        path.each do |key|
          data = data[key] ||= {}
        end
        data[last] = value
      end

      def get_in(data, path)
        path.each do |key|
          data = data[key]
        end
        data
      end

      def resolve_batches(scope, thread, query_object, merge_target)
        while query_object.accumulator.any?
          query_object.accumulator.resolve_all do |frame, value|
            # TODO cache on frame
            field_defn = scope.get_field(frame.type, frame.node.definition_name)
            finished_value = resolve_value(scope, thread, frame, value, field_defn, field_defn.type)
            set_in(merge_target, frame.path, finished_value)
          end
        end
      end
    end
  end
end
