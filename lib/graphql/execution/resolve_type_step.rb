# frozen_string_literal: true
module GraphQL
  module Execution
    class ResolveTypeStep
      def self.resolve_type(type, object, query)
        query.current_trace.begin_resolve_type(type, object, query.context)
        resolved_type_response = query.resolve_type(type, object)
        resolved_type = if resolved_type_response.is_a?(Array)
          resolved_type_response.first
        else
          resolved_type_response
        end
        query.current_trace.end_resolve_type(type, object, query.context, resolved_type)
        resolved_type_response
      end

      def self.assert_valid_resolved_type(abstract_type, resolved_type, object, field_resolution_step, query: field_resolution_step.selections_step.query)
        possible_types = query.types.possible_types(abstract_type)
        if !possible_types.include?(resolved_type)
          err_class = abstract_type::UnresolvedTypeError
          type_error = err_class.new(object, field_resolution_step.field_definition, abstract_type, resolved_type, possible_types)
          query.schema.type_error(type_error, query.context)
        end
      end
    end
  end
end
