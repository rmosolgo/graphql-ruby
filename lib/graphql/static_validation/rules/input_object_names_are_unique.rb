# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module InputObjectNamesAreUnique
      def on_input_object(node, parent)
        validate_input_fields(node)
        super
      end

      private

      def validate_input_fields(node)
        input_field_defns = node.arguments
        input_fields_by_name = Hash.new { |h, k| h[k] = [] }
        input_field_defns.each { |a| input_fields_by_name[a.name] << a }

        input_fields_by_name.each do |name, defns|
          if defns.size > 1
            error = GraphQL::StaticValidation::InputObjectNamesAreUniqueError.new(
              "There can be only one input field named \"#{name}\"",
              nodes: defns,
              name: name
            )
            add_error(error)
          end
        end
      end
    end
  end
end
