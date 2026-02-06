# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class TypeDefinition
      def initialize(name)
        @name = name
        @field_definitions = {}
        @resolver_methods = {}
      end

      attr_reader :resolver_methods, :name, :field_definitions

      def field_definition(name, node)
        @field_definitions[name] = FieldDefinition.new(self, name, node)
      end

      def resolver_method(name, node)
        @resolver_methods[name] = ResolverMethod.new(name, node)
      end
    end
  end
end
