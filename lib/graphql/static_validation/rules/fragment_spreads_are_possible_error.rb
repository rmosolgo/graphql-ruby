# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class FragmentSpreadsArePossibleError < StaticValidation::Error
      #: String
      attr_reader :type_name
      #: String
      attr_reader :fragment_name
      #: String
      attr_reader :parent_name

      #: (String message, type: String, fragment_name: String, parent: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, type:, fragment_name:, parent:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @type_name = type #: String
        @fragment_name = fragment_name #: String
        @parent_name = parent #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "typeName" => type_name,
          "fragmentName" => fragment_name,
          "parentName" => parent_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "cannotSpreadFragment"
      end
    end
  end
end
