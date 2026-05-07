# frozen_string_literal: true
module GraphQL
  module Execution
    class ResolveTypeStep
      def self.resolve_type(type, object, field_step, query)
        query.current_trace.begin_resolve_type(type, object, query.context)
        resolved_type, new_value = query.resolve_type(type, object)
        if field_step.runner.resolves_lazies && field_step.runner.lazy?(resolved_type)
          # TODO batch this in a job object
          resolved_type, new_value = field_step.sync(resolved_type)
        end
        query.current_trace.end_resolve_type(type, object, query.context, resolved_type)
        possible_types = query.types.possible_types(type)
        if !possible_types.include?(resolved_type)
          err_class = type::UnresolvedTypeError
          type_error = err_class.new(object, field_step.field_definition, type, resolved_type, possible_types)
          query.schema.type_error(type_error, query.context)
          nil
        else
          return resolved_type, new_value
        end
      end
    end
  end
end
