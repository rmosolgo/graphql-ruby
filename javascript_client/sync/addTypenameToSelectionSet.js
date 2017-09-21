// This file/concept was borrowed from https://github.com/apollographql/apollo-client/blob/fec6457746b1cb63c759f128349e66499328ae43/src/queries/queryTransform.ts#L22-L56

const TYPENAME_FIELD = {
  kind: "Field",
  name: {
    kind: "Name",
    value: "__typename",
  },
}

function addTypenameToSelectionSet(selectionSet, isRoot) {
  if (selectionSet.selections) {
    if (!isRoot) {
      const alreadyHasThisField = selectionSet.selections.some(function(selection) {
        return (
          selection.kind === "Field" && selection.name.value === "__typename"
        )
      })

      if (!alreadyHasThisField) {
        selectionSet.selections.push(TYPENAME_FIELD);
      }
    }

    selectionSet.selections.forEach(function(selection) {
      // Must not add __typename if we're inside an introspection query
      if (selection.kind === "Field") {
        if (selection.name.value.lastIndexOf("__", 0) !== 0 && selection.selectionSet) {
          addTypenameToSelectionSet(selection.selectionSet, false);
        }
      } else if (selection.kind === "InlineFragment") {
        if (selection.selectionSet) {
          addTypenameToSelectionSet(selection.selectionSet, false);
        }
      }
    })
  }
}

module.exports = addTypenameToSelectionSet
