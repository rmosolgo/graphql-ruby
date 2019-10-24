# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class ArgumentLiteralsAreCompatibleError < StaticValidation::Error
      attr_reader :type_name
      attr_reader :argument_name

      def initialize(message, path: nil, nodes: [], type:, argument: nil, extensions: nil)
        super(message, path: path, nodes: nodes)
        @type_name = type
        @argument_name = argument
        @extensions = extensions
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "typeName" => type_name
        }.tap { |h| h["argumentName"] = argument_name unless argument_name.nil? }
        extensions.merge!(@extensions) unless @extensions.nil?
        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "argumentLiteralsIncompatible"
      end
    end
  end
end
