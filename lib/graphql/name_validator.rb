# frozen_string_literal: true
module GraphQL
  class NameValidator
    VALID_NAME_REGEX = /^[_a-zA-Z][_a-zA-Z0-9]*$/

    def self.validate!(name)
      unless valid?(name)
        raise(
          GraphQL::InvalidNameError,
          "Names must match #{VALID_NAME_REGEX} but '#{name}' does not"
        )
      end
    end

    def self.valid?(name)
      name =~ VALID_NAME_REGEX
    end
  end
end
