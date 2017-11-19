module GraphQL
  module Language
    module Nodes
      class AstGenerator
        def self.from_schema(schema)
        end

        def initialize(schema)
          @schema = schema
        end

        def generate
          GraphQL::Language::Nodes::Document.new(
            definitions: definitions
          )
        end

        private

        def definitions

        end
      end
    end
  end
end
