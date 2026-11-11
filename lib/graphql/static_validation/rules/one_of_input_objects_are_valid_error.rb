# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class OneOfInputObjectsAreValidError < StaticValidation::Error
      #: String
      attr_reader :input_object_type

      #: (String message, path: Array[String | Integer]?, nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode], input_object_type: String) -> void
      def initialize(message, path:, nodes:, input_object_type:)
        super(message, path: path, nodes: nodes)
        @input_object_type = input_object_type #: String
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "inputObjectType" => input_object_type
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "invalidOneOfInputObject"
      end
    end
  end
end
