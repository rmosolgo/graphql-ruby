# frozen_string_literal: true
module GraphQL
  class UnauthorizedFieldError < GraphQL::UnauthorizedError
    # @return [Field] the field that failed the authorization check
    attr_reader :field

    def initialize(message = nil, object: nil, type: nil, context: nil, field: nil)
      if message.nil? && [object, field, type].any?(&:nil?)
        raise ArgumentError, "#{self.class.name} requires either a message or keywords"
      end

      @field = field
      # message ||= "An instance of #{object.class} failed #{type.name}'s authorization check on field #{field.name}"
      message ||= "An instance of #{object.class} failed the authorization check on field #{field.name}"
      super(message, object: object, type: type, context: context)
    end
  end
end
