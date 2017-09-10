# frozen_string_literal: true
module GraphQL
  class NameValidator
    def self.validate!(name)
      unless valid?(name)
        raise(
          GraphQL::InvalidNameError,
          "Names must match /^[_a-zA-Z][_a-zA-Z0-9]*$/ but '#{name}' does not"
        )
      end
    end

    def self.valid?(name)
      name =~ /^[_a-zA-Z][_a-zA-Z0-9]*$/
    end
  end
end
