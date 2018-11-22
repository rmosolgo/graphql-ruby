# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FragmentsAreNamed
      def on_fragment_definition(node, _parent)
        if node.name.nil?
          add_error("Fragment definition has no name", node, extensions: {
            "rule": "StaticValidation::FragmentsAreNamed"
          })
        end
        super
      end
    end
  end
end
