# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    class FragmentNamesAreUniqueError < StaticValidation::Error
      attr_reader :fragment_name

      def initialize(message, name:, path: nil, nodes: [])
        super(message, path: path, nodes: nodes)
        @fragment_name = name
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "fragmentName" => fragment_name
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "fragmentNotUnique"
      end
    end
  end
end
