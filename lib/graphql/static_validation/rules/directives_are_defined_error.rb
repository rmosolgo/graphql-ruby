# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class DirectivesAreDefinedError < Message
      attr_reader :directive_name

      def initialize(message, path: nil, nodes: [], directive:)
        super(message, path: path, nodes: nodes)
        @directive_name = directive
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "directiveName" => directive_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      private
      def code
        "undefinedDirective"
      end
    end
  end
end
