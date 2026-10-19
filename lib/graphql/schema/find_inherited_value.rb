# frozen_string_literal: true
# typed: true
module GraphQL
  class Schema
    #--
    # @requires_ancestor: Module
    module FindInheritedValue
      def self.extended(child_cls)
        child_cls.singleton_class.include(GraphQL::EmptyObjects)
      end

      def self.included(child_cls)
        child_cls.include(GraphQL::EmptyObjects)
      end

      private

      def find_inherited_value(method_name, default_value = nil)
        if self.is_a?(Class)
          superclass.respond_to?(method_name, true) ? superclass.send(method_name) : default_value
        else
          ancestors.each do |ancestor|
            next if ancestor.equal?(self)
            if ancestor.respond_to?(method_name, true)
              return ancestor.send(method_name)
            end
          end
          default_value
        end
      end
    end
  end
end
