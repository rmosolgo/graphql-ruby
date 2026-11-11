# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class RequiredInputObjectAttributesArePresentError < StaticValidation::Error
      #: String
      attr_reader :argument_type
      #: String
      attr_reader :argument_name
      #: String
      attr_reader :input_object_type

      #: (String message, path: Array[String | Integer]?, nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode], argument_type: String, argument_name: String, input_object_type: String) -> void
      def initialize(message, path:, nodes:, argument_type:, argument_name:, input_object_type:)
        super(message, path: path, nodes: nodes)
        @argument_type = argument_type #: String
        @argument_name = argument_name #: String
        @input_object_type = input_object_type #: String
      end

      # A hash representation of this Message
      #: () -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "argumentName" => argument_name,
          "argumentType" => argument_type,
          "inputObjectType" => input_object_type,
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: () -> String
      def code
        "missingRequiredInputObjectAttribute"
      end
    end
  end
end
