# frozen_string_literal: true
module GraphQL
  module Language
    module Nodes
      class BuildFromSchemaDefinition
        def initialize(schema, context: nil, only: nil, except: nil, include_builtins: false)
          @schema = schema
          @context = context
          @only = only
          @except = except
          @include_builtins = include_builtins

          filter = GraphQL::Filter.new(only: only, except: except)

          @warden = GraphQL::Schema::Warden.new(filter, schema: @schema, context: @context)
        end

        def document
          GraphQL::Language::Nodes::Document.new(definitions: definitions)
        end

        private

        def definitions
          definitions = []

          unless schema.root_types_respect_convention?
            definitions << schema.to_ast_node
          end

          definitions += types
          definitions += directives

          definitions
        end

        def types
          types = warden.types

          unless include_builtins
            types = types.reject { |type| type.default_scalar? || type.introspection? }
          end

          types.map(&:to_ast_node)
        end

        def directives
          directives = warden.directives

          unless include_builtins
            directives = directives.reject(&:default_directive?)
          end

          directives.map(&:to_ast_node)
        end

        attr_reader :warden, :include_builtins, :schema
      end
    end
  end
end
