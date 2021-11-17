# frozen_string_literal: true

module GraphQL
  module Deprecation
    def self.warn(message)
      Kernel.warn(message)
    end
  end
end
