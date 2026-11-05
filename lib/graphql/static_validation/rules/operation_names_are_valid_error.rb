# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    class OperationNamesAreValidError < StaticValidation::Error
      #: String?
      attr_reader :operation_name

      #: (String message, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode], ?name: String?) -> void
      def initialize(message, path: nil, nodes: [], name: nil)
        super(message, path: path, nodes: nodes)
        @operation_name = name #: String?
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code
        }.tap { |h| h["operationName"] = operation_name unless operation_name.nil? }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "uniquelyNamedOperations"
      end
    end
  end
end
