# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    class ArgumentLiteralsAreCompatibleError < StaticValidation::Error
      #: String
      attr_reader :type_name
      #: String?
      attr_reader :argument_name
      #: GraphQL::Schema::Argument?
      attr_reader :argument
      #: untyped
      attr_reader :value

      #: (String message, type: String, ?path: Array[String | Integer]?, ?nodes: GraphQL::Language::Nodes::AbstractNode | Array[GraphQL::Language::Nodes::AbstractNode], ?argument_name: String?, ?extensions: Hash[String, untyped]?, ?coerce_extensions: Hash[String, untyped]?, ?argument: GraphQL::Schema::Argument?, ?value: untyped) -> void
      def initialize(message, type:, path: nil, nodes: [], argument_name: nil, extensions: nil, coerce_extensions: nil, argument: nil, value: nil)
        super(message, path: path, nodes: nodes)
        @type_name = type #: String
        @argument_name = argument_name #: String?
        @extensions = extensions #: Hash[String, untyped]?
        @coerce_extensions = coerce_extensions #: Hash[String, untyped]?
        @argument = argument #: GraphQL::Schema::Argument?
        @value = value #: untyped
      end

      # A hash representation of this Message
      #: -> Hash[String, untyped]
      def to_h
        if @coerce_extensions
          extensions = @coerce_extensions
          # This is for legacy compat -- but this key is supposed to be a GraphQL type name :confounded:
          extensions["typeName"] = "CoercionError"
        else
          extensions = {
            "code" => code,
            "typeName" => type_name
          }

          if argument_name
            extensions["argumentName"] = argument_name
          end
        end

        extensions.merge!(@extensions) unless @extensions.nil?
        super.merge({
          "extensions" => extensions
        })
      end

      #: -> String
      def code
        "argumentLiteralsIncompatible"
      end
    end
  end
end
