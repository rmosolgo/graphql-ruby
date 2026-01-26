# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      module FieldCompatibility
        def resolve_all_load_arguments(arguments, argument_owner, context)
          arg_defns = context.types.arguments(argument_owner)
          arg_defns.each do |arg_defn|
            if arg_defn.loads
              id = arguments.delete(arg_defn.keyword)
              if id
                value = context.schema.object_from_id(id, context)
                arguments[arg_defn.keyword] = value
              end
            elsif (input_type = arg_defn.type.unwrap).kind.input_object? # TODO lists
              value = arguments[arg_defn.keyword]
              resolve_all_load_arguments(value, input_type, context)
            end
          end
        end

        def resolve_all(frs, objects, context, **kwargs)
          resolve_all_load_arguments(kwargs, self, context)
          @resolve_all_method ||= :"all_#{@method_sym}"
          if extras.include?(:lookahead)
            kwargs[:lookahead] = Execution::Lookahead.new(
              query: context.query,
              ast_nodes: frs.ast_nodes || Array(frs.ast_node),
              field: self,
            )
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
            objects.map { |o|
              resolver_inst = @resolver_class.new(object: o, context: context, field: self)
              if kwargs.empty?
                resolver_inst.public_send(@resolver_class.resolver_method)
              else
                resolver_inst.public_send(@resolver_class.resolver_method, **kwargs)
              end
            }
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
