import { visit, ASTNode, FieldNode, InlineFragmentNode } from "graphql"

const TYPENAME_FIELD: FieldNode = {
  kind: "Field",
  name: {
    kind: "Name",
    value: "__typename",
  },
  selectionSet: {
    kind: "SelectionSet",
    selections: []
  }
}

function addTypenameIfAbsent(node: FieldNode | InlineFragmentNode): undefined | FieldNode | InlineFragmentNode {
  if (node.selectionSet) {
    const alreadyHasThisField = node.selectionSet.selections.some(function(selection) {
      return (
        selection.kind === "Field" && selection.name.value === "__typename"
      )
    })

    if (!alreadyHasThisField) {
      return {
        ...node,
        selectionSet: {
          ...node.selectionSet,
          selections: [...node.selectionSet.selections, TYPENAME_FIELD]
        }
      }
    } else {
      return undefined
    }
  } else {
    return undefined
  }
}

function addTypenameToSelectionSet(node: ASTNode) {
  var visitor = {
    Field: {
      leave: addTypenameIfAbsent,
    },
    InlineFragment: {
      leave: addTypenameIfAbsent,
    }
  }
  var newNode = visit(node, visitor)
  return newNode
}

export {
  addTypenameToSelectionSet,
  addTypenameIfAbsent
}

