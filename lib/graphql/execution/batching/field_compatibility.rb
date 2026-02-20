# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      module FieldCompatibility
        def resolve_all_load_arguments(frs, object_from_id_receiver, arguments, argument_owner, context)
          arg_defns = context.types.arguments(argument_owner)
          arg_defns.each do |arg_defn|
            if arg_defn.loads
              if arguments.key?(arg_defn.keyword)
                id = arguments.delete(arg_defn.keyword)
                if !id.nil?
                  value = if arg_defn.type.list?
                    id.map {  |inner_id|
                      object_from_id_receiver.load_and_authorize_application_object(arg_defn, inner_id, context)
                    }
                  else
                    object_from_id_receiver.load_and_authorize_application_object(arg_defn, id, context)
                  end

                  if frs.runner.resolves_lazies
                    value = frs.sync(value)
                  end
                  if value.is_a?(GraphQL::Error)
                    value.path = frs.path
                    return value
                  end
                else
                  value = nil
                end
                arguments[arg_defn.keyword] = value
              end
            elsif (input_type = arg_defn.type.unwrap).kind.input_object? &&
                (value = arguments[arg_defn.keyword]) # TODO lists
              resolve_all_load_arguments(frs, object_from_id_receiver, value, input_type, context)
            end
          end
          nil
        end

        def resolve_batch(frs, objects, context, kwargs)
          if @batch_mode && !:direct_send.equal?(@batch_mode)
            return super
          end

          if !@resolver_class
            maybe_err = resolve_all_load_arguments(frs, self, kwargs, self, context)
            if maybe_err
              return maybe_err
            end
          end
          if extras.include?(:lookahead)
            if kwargs.frozen?
              kwargs = kwargs.dup
            end
            kwargs[:lookahead] = Execution::Lookahead.new(
              query: context.query,
              ast_nodes: frs.ast_nodes || Array(frs.ast_node),
              field: self,
            )
          end

          if extras.include?(:ast_node)
            if kwargs.frozen?
              kwargs = kwargs.dup
            end
            kwargs[:ast_node] = frs.ast_node
          end

          if @owner.method_defined?(@resolver_method)
            results = []
            frs.selections_step.graphql_objects.each_with_index do |obj_inst, idx|
              if frs.object_is_authorized[idx]
                if dynamic_introspection
                  obj_inst = @owner.wrap(obj_inst, context)
                end
                results << with_extensions(obj_inst, kwargs, context) do |obj, ruby_kwargs|
                  if ruby_kwargs.empty?
                    obj.public_send(@resolver_method)
                  else
                    obj.public_send(@resolver_method, **ruby_kwargs)
                  end
                end
              end
            end
            results
          elsif @resolver_class
            objects.map do |o|
              resolver_inst_kwargs = kwargs.dup
              resolver_inst = @resolver_class.new(object: o, context: context, field: self)
              maybe_err = resolve_all_load_arguments(frs, resolver_inst, resolver_inst_kwargs, self, context)
              if maybe_err
                next maybe_err
              end
              resolver_inst_kwargs = if @resolver_class < Schema::HasSingleInputArgument
                resolver_inst_kwargs[:input]
              else
                resolver_inst_kwargs
              end
              with_extensions(o, resolver_inst_kwargs, context) do |obj, ruby_kwargs|
                resolver_inst.object = obj
                resolver_inst.prepared_arguments = ruby_kwargs
                is_authed, new_return_value = resolver_inst.authorized?(**ruby_kwargs)
                if frs.runner.resolves_lazies && frs.runner.schema.lazy?(is_authed)
                  is_authed, new_return_value = frs.runner.schema.sync_lazy(is_authed)
                end
                if is_authed
                  resolver_inst.call_resolve(ruby_kwargs)
                else
                  new_return_value
                end
              end
            rescue RuntimeError => err
              err
            rescue StandardError => stderr
              begin
                context.query.handle_or_reraise(stderr)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
          elsif objects.first.is_a?(Hash)
            objects.map { |o| o[method_sym] || o[graphql_name] }
          elsif objects.first.is_a?(Interpreter::RawValue)
            objects
          else
            # need to use connection extension if present, and extensions expect object type instances
            if extensions.empty?
              objects.map { |o| o.public_send(@method_sym)}
            else
              results = []
              frs.selections_step.graphql_objects.each_with_index do |obj_inst, idx|
                if frs.object_is_authorized[idx]
                  results << with_extensions(obj_inst, EmptyObjects::EMPTY_HASH, context) do |obj, arguments|
                    if arguments.empty?
                      obj.object.public_send(@method_sym)
                    else
                      obj.object.public_send(@method_sym, **arguments)
                    end
                  end
                end
              end
              results
            end
          end
        end
      end
    end
  end
end
