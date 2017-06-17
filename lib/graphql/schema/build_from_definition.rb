# frozen_string_literal: true
require "graphql/schema/build_from_definition/builder"
require "graphql/schema/build_from_definition/define_instrumentation"
require "graphql/schema/build_from_definition/resolve_map"

module GraphQL
  class Schema
    module BuildFromDefinition
      class << self
        def from_definition(definition_string, default_resolve:, parser:, definitions:)
          document = parser.parse(definition_string)
          Builder.build(document, default_resolve: default_resolve, definitions: definitions)
        end
      end

      # @api private
      DefaultParser = GraphQL::Language::Parser

      # @api private
      module DefaultResolve
        def self.call(type, field, obj, args, ctx)
          if field.arguments.any?
            obj.public_send(field.name, args, ctx)
          else
            obj.public_send(field.name)
          end
        end
      end
    end
  end
end
