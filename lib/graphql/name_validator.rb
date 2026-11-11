# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  class NameValidator
    VALID_NAME_REGEX = /^[_a-zA-Z][_a-zA-Z0-9]*$/

    #: (String | Symbol name) -> void
    def self.validate!(name)
      name = name.is_a?(String) ? name : name.to_s
      raise GraphQL::InvalidNameError.new(name, VALID_NAME_REGEX) unless name.match?(VALID_NAME_REGEX)
    end
  end
end
