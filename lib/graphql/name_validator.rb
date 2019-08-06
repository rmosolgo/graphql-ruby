# frozen_string_literal: true
module GraphQL
  class NameValidator
    VALID_NAME_REGEX = /^[_a-zA-Z][_a-zA-Z0-9]*$/

    def self.validate!(name)
      raise GraphQL::InvalidNameError.new(name, VALID_NAME_REGEX) unless valid?(name)
    end

    private

    def self.valid?(name)
      name =~ VALID_NAME_REGEX
    end
  end
end
