# frozen_string_literal: true
# typed: true
module GraphQL
  module Introspection
    class BaseObject < GraphQL::Schema::Object
      introspection(true)

      def self.field(*args, **kwargs, &block)
        kwargs[:introspection] = true
        super
      end
    end
  end
end
