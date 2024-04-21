module GraphQL
  module Bulk
    module Visitors
      class AddPaginationToQueryVisitor < GraphQL::Language::Visitor
        def initialize(document, connection_node)
          super(document)
          @connection_node = connection_node
        end

        def on_operation_definition(node, parent)
          modified_node = node.merge_variable(
            name: "__appPlatformCursor",
            type: GraphQL::Language::Nodes::TypeName.new(name: "String!"),
          )
          super(modified_node, parent)
        end

        def on_field(node, parent)
          if node == @connection_node
            old_arguments = node.arguments
            new_arguments = [
              GraphQL::Language::Nodes::Argument.new(
                name: "after",
                value: GraphQL::Language::Nodes::VariableIdentifier.new(name: "__appPlatformCursor"),
              ),
              GraphQL::Language::Nodes::Argument.new(
                name: "first",
                value: 50,
              ),
            ]

            old_selections = node.selections
            new_selections = [
              GraphQL::Language::Nodes::Field.new(
                name: "pageInfo",
                field_alias: "__appPlatformPageInfo",
                selections: [
                  GraphQL::Language::Nodes::Field.new(
                    name: "hasNextPage"
                  ),
                  GraphQL::Language::Nodes::Field.new(
                    name: "endCursor"
                  ),
                ]
              ),
            ]

            modified_node = node.merge(
              {
                arguments: old_arguments + new_arguments,
                selections: old_selections + new_selections,
              }
            )

            return super(modified_node, parent)
          end

          super
        end
      end
    end
  end
end
