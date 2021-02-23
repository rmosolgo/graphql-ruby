# frozen_string_literal: true

module GraphQL
  module Deprecation
    def self.warn(message)
      if defined?(ActiveSupport::Deprecation)
        ActiveSupport::Deprecation.warn(message)
      else
        Kernel.warn(message)
      end
    end
  end
end
