# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class ArgumentsAreDefinedError < StaticValidation::Error
      #: String
      attr_reader :name
      #: String
      attr_reader :type_name
      #: String
      attr_reader :argument_name
      #: GraphQL::Schema::Field | singleton(GraphQL::Schema::Directive) | GraphQL::Schema::Member::type_definition
      attr_reader :parent

      #: (String message, name: String, type: String, argument_name: String, parent: GraphQL::Schema::Field | singleton(GraphQL::Schema::Directive) | GraphQL::Schema::Member::type_definition, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode]) -> void
      def initialize(message, name:, type:, argument_name:, parent:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @name = name #: String
        @type_name = type #: String
        @argument_name = argument_name #: String
        @parent = parent #: GraphQL::Schema::Field | singleton(GraphQL::Schema::Directive) | GraphQL::Schema::Member::type_definition
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "name" => name,
          "typeName" => type_name,
          "argumentName" => argument_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "argumentNotAccepted"
      end
    end
  end
end
