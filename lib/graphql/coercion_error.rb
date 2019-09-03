# frozen_string_literal: true
module GraphQL
  class CoercionError < GraphQL::Error
    # @return [Hash] Optional custom data for error objects which will be added
    # under the `extensions` key.
    attr_accessor :extensions

    def initialize(message, extensions: nil)
      @extensions = extensions
      super(message)
    end
  end
end
