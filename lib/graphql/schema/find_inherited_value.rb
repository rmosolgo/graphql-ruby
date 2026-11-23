# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  class Schema
    #--
    # @requires_ancestor: Module
    module FindInheritedValue
      #: (Module[untyped] child_cls) -> void
      def self.extended(child_cls)
        child_cls.singleton_class.include(GraphQL::EmptyObjects)
      end

      #: (Module[untyped] child_cls) -> void
      def self.included(child_cls)
        child_cls.include(GraphQL::EmptyObjects)
      end

      private

      # Returns whatever the inherited configuration method returns, so the result is `untyped`.
      #: (Symbol method_name, ?untyped default_value) -> untyped
      def find_inherited_value(method_name, default_value = nil)
        if self.is_a?(Class)
          superclass.respond_to?(method_name, true) ? superclass.__send__(method_name) : default_value
        else
          ancestors.each do |ancestor|
            next if ancestor.equal?(self)
            if ancestor.respond_to?(method_name, true)
              return ancestor.__send__(method_name)
            end
          end
          default_value
        end
      end
    end
  end
end
