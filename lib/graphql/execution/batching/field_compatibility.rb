# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      module FieldCompatibility
        def resolve_batch(frs, objects, context, kwargs)
          if @batch_mode && !:direct_send.equal?(@batch_mode)
            return super
          end

          if @owner.method_defined?(@resolver_method)
            results = []
            frs.selections_step.graphql_objects.each_with_index do |obj_inst, idx|
              if frs.object_is_authorized[idx]
                if dynamic_introspection
                  obj_inst = @owner.wrap(obj_inst, context)
                end
                results << if kwargs.empty?
                  obj_inst.public_send(@resolver_method)
                else
                  obj_inst.public_send(@resolver_method, **kwargs)
                end
              end
            end
            results
          elsif objects.first.is_a?(Hash)
            objects.map { |o| o[method_sym] || o[graphql_name] }
          elsif objects.first.is_a?(Interpreter::RawValue)
            objects
          else
            objects.map { |o| o.public_send(@method_sym)}
          end
        end
      end
    end
  end
end
