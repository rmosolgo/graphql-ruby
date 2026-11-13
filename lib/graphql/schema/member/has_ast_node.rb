# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  class Schema
    class Member
      module HasAstNode
        #: (singleton(GraphQL::Schema::Member) | singleton(GraphQL::Schema) child_cls) -> void
        def self.extended(child_cls)
          super
          child_cls.ast_node = nil
        end

        #: (singleton(GraphQL::Schema::Member) | singleton(GraphQL::Schema) child_cls) -> void
        def inherited(child_cls)
          super
          child_cls.ast_node = nil
        end

        # If this schema was parsed from a `.graphql` file (or other SDL),
        # this is the AST node that defined this part of the schema.
        #: (?GraphQL::Language::Nodes::AbstractNode? new_ast_node) -> GraphQL::Language::Nodes::AbstractNode?
        def ast_node(new_ast_node = nil)
          if new_ast_node
            @ast_node = new_ast_node #: GraphQL::Language::Nodes::AbstractNode?
          elsif defined?(@ast_node)
            @ast_node
          else
            nil
          end
        end

        #: GraphQL::Language::Nodes::AbstractNode?
        attr_writer :ast_node
      end
    end
  end
end
