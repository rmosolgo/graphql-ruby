# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Scalars _can't_ have selections
    # Objects _must_ have selections
    module FieldsHaveAppropriateSelections
      include GraphQL::StaticValidation::Error::ErrorHelper

      def on_field(node, parent)
        field_defn = field_definition
        if validate_field_selections(node, field_defn.type.unwrap)
          super
        end
      end

      def on_operation_definition(node, _parent)
        if validate_field_selections(node, type_definition)
          super
        end
      end

      private


      def validate_field_selections(ast_node, resolved_type)
        msg = if resolved_type.nil?
          nil
        elsif resolved_type.kind.leaf?
          if !ast_node.selections.empty?
            selection_strs = ast_node.selections.map do |n|
              case n
              when GraphQL::Language::Nodes::InlineFragment
                "\"... on #{n.type.name} { ... }\""
              when GraphQL::Language::Nodes::Field
                "\"#{n.name}\""
              when GraphQL::Language::Nodes::FragmentSpread
                "\"#{n.name}\""
              else
                raise "Invariant: unexpected selection node: #{n}"
              end
            end
            "Selections can't be made on #{resolved_type.kind.name.sub("_", " ").downcase}s (%{node_name} returns #{resolved_type.graphql_name} but has selections [#{selection_strs.join(", ")}])"
          else
            nil
          end
        elsif ast_node.selections.empty?
          return_validation_error = true
          legacy_invalid_empty_selection_result = nil
          if !resolved_type.kind.fields?
            case @schema.allow_legacy_invalid_empty_selections_on_union
            when true
              legacy_invalid_empty_selection_result = @schema.legacy_invalid_empty_selections_on_union(@context.query)
              case legacy_invalid_empty_selection_result
              when :return_validation_error
                # keep `return_validation_error = true`
              when String
                return_validation_error = false
                # the string is returned below
              when nil
                # No error:
                return_validation_error = false
                legacy_invalid_empty_selection_result = nil
              else
                raise GraphQL::InvariantError, "Unexpected return value from legacy_invalid_empty_selections_on_union, must be `:return_validation_error`, String, or nil (got: #{legacy_invalid_empty_selection_result.inspect})"
              end
            when false
              # pass -- error below
            else
              return_validation_error = false
              @context.query.logger.warn("Unions require selections but #{ast_node.alias || ast_node.name} (#{resolved_type.graphql_name}) doesn't have any. This will fail with a validation error on a future GraphQL-Ruby version. More info: https://graphql-ruby.org/api-doc/#{GraphQL::VERSION}/GraphQL/Schema.html#allow_legacy_invalid_empty_selections_on_union-class_method")
            end
          end
          if return_validation_error
            "Field must have selections (%{node_name} returns #{resolved_type.graphql_name} but has no selections. Did you mean '#{ast_node.name} { ... }'?)"
          else
            legacy_invalid_empty_selection_result
          end
        else
          nil
        end

        if msg
          node_name = case ast_node
          when GraphQL::Language::Nodes::Field
            "field '#{ast_node.name}'"
          when GraphQL::Language::Nodes::OperationDefinition
            if ast_node.name.nil?
              "anonymous query"
            else
              "#{ast_node.operation_type} '#{ast_node.name}'"
            end
          else
            raise("Unexpected node #{ast_node}")
          end
          extensions = {
            "rule": "StaticValidation::FieldsHaveAppropriateSelections",
            "name": node_name.to_s
          }
          unless resolved_type.nil?
            extensions["type"] = resolved_type.to_type_signature
          end
          add_error(GraphQL::StaticValidation::FieldsHaveAppropriateSelectionsError.new(
            msg % { node_name: node_name },
            nodes: ast_node,
            node_name: node_name.to_s,
            type: resolved_type.nil? ? nil : resolved_type.graphql_name,
          ))
          false
        else
          true
        end
      end
    end
  end
end
