# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class ArgumentsAreDefinedError < StaticValidation::Error
      attr_reader :name
      attr_reader :type_name
      attr_reader :argument_name

      def initialize(message, path: nil, nodes: [], name:, type:, argument:)
        super(message, path: path, nodes: nodes)
        @name = name
        @type_name = type
        @argument_name = argument
      end

      # A hash representation of this Message
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

      def code
        "argumentNotAccepted"
      end
    end
  end
end
