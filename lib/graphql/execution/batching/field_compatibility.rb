# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      module FieldCompatibility
        def initialize(...)
          super(...)
          @resolve_all_method = nil
        end

        def resolve_all_load_arguments(frs, object_from_id_receiver, arguments, argument_owner, context)
          arg_defns = context.types.arguments(argument_owner)
          arg_defns.each do |arg_defn|
            if arg_defn.loads
              if arguments.key?(arg_defn.keyword) && !arguments[arg_defn.keyword].nil?
                id = arguments.delete(arg_defn.keyword)
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
                arguments[arg_defn.keyword] = value
              end
            elsif (input_type = arg_defn.type.unwrap).kind.input_object? && value = arguments[arg_defn.keyword] # TODO lists
              resolve_all_load_arguments(frs, object_from_id_receiver, value, input_type, context)
            end
          end
          nil
        end

        def resolve_all(frs, objects, context, **kwargs)
          if !@resolver_class
            maybe_err = resolve_all_load_arguments(frs, self, kwargs, self, context)
            if maybe_err
              return nil
            end
          end
          @resolve_all_method ||= :"all_#{@method_sym}"
          if extras.include?(:lookahead)
            kwargs[:lookahead] = Execution::Lookahead.new(
              query: context.query,
              ast_nodes: frs.ast_nodes || Array(frs.ast_node),
              field: self,
            )
          end

          if extras.include?(:ast_node)
            kwargs[:ast_node] = frs.ast_node
          end

          if @owner.respond_to?(@resolve_all_method)
            if kwargs.empty?
              @owner.public_send(@resolve_all_method, objects, context)
            else
              @owner.public_send(@resolve_all_method, objects, context, **kwargs)
            end
          elsif @owner.method_defined?(@resolver_method)
            frs.selections_step.graphql_objects.map do |obj_inst|
              if dynamic_introspection
                obj_inst = @owner.wrap(obj_inst, context)
              end
              if kwargs.empty?
                obj_inst.public_send(@resolver_method)
              else
                obj_inst.public_send(@resolver_method, **kwargs)
              end
            end
          elsif @resolver_class
            objects.map do |o|
              resolver_inst_kwargs = kwargs.dup
              resolver_inst = @resolver_class.new(object: o, context: context, field: self)
              maybe_err = resolve_all_load_arguments(frs, resolver_inst, resolver_inst_kwargs, self, context)
              if maybe_err
                next nil
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
            rescue GraphQL::Error => err
              err.path = frs.path
              context.errors << err
              nil
            rescue StandardError => stderr
              begin
                context.query.handle_or_reraise(stderr)
              rescue GraphQL::ExecutionError => ex_err
                ex_err.path = frs.path
                context.errors << ex_err
                nil
              end
            end
          elsif objects.first.is_a?(Hash)
            objects.map { |o| o[method_sym] || o[graphql_name] }
          elsif objects.first.is_a?(Interpreter::RawValue)
            objects
          else
            objects.map { |o| o.public_send(@method_sym) }
          end
        end
      end

      GraphQL::Schema::Field.include(FieldCompatibility)
    end
  end
end
