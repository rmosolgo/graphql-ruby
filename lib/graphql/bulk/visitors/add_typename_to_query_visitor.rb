module GraphQL
  module Bulk
    module Visitors
      class AddTypenameToQueryVisitor < GraphQL::Language::Visitor
        def on_field(node, parent)
          unless node.selections.empty?
            has_typename = false
            node.selections.each do |selection|
              has_typename = true if selection.name == "__typename"
            end

            return super if has_typename

            modified_node = node.merge_selection(
              name: "__typename"
            )
            return super(modified_node, parent)
          end

          super
        end
      end
    end
  end
end
