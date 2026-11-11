# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class DirectivesAreInValidLocationsError < StaticValidation::Error
      #: String
      attr_reader :target_name
      #: String?
      attr_reader :name

      #: (String message, target: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode], ?name: String?) -> void
      def initialize(message, target:, path: nil, nodes: [], name: nil)
        super(message, path: path, nodes: nodes)
        @target_name = target #: String
        @name = name #: String?
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        extensions = {
          "code" => code,
          "targetName" => target_name
        }.tap { |h| h["name"] = name unless name.nil? }

        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "directiveCannotBeApplied"
      end
    end
  end
end
