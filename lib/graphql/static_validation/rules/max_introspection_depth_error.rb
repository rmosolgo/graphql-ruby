# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    class MaxIntrospectionDepthError < StaticValidation::Error
      def to_h
        super.merge("extensions" => {"code" => code})
      end

      def code
        "maxIntrospectionDepthExceeded"
      end
    end
  end
end
