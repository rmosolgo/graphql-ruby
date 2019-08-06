# frozen_string_literal: true
module GraphQL
  module Introspection
    class BaseObject < GraphQL::Schema::Object
      def self.field(*args, **kwargs, &block)
        kwargs[:introspection] = true
        super(*args, **kwargs, &block)
      end

      def self.inherited(child_class)
        child_class.introspection(true)
        super
      end
    end
  end
end
