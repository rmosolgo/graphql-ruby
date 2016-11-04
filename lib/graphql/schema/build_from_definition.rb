require 'graphql/schema/build_from_definition/builder'

module GraphQL
  class Schema
    module BuildFromDefinition
      def self.included(base)
        base.extend(ClassMethods)
      end

      class InvalidDocumentError < Error; end;

      module ClassMethods
        # Create schema from an IDL schema.
        # @param definition_string String A schema definition string
        # @return [GraphQL::Schema] the schema described by `document`
        def from_definition(definition_string, builder: GraphQL::Schema::BuildFromDefinition::Builder)
          builder.new(definition_string).build
        end
      end
    end
  end
end
