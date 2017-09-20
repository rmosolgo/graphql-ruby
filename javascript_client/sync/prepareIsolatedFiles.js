var fs = require("fs")
var graphql = require("graphql")
var addTypenameToSelectionSet = require("./addTypenameToSelectionSet")

/**
 * Read a bunch of GraphQL files and treat them as islands.
 * Don't join any fragments from other files.
 * Don't make assertions about name uniqueness.
 *
 */
function prepareIsolatedFiles(filenames, addTypename) {
  return filenames.map(function(filename) {
    var fileOperationBody = fs.readFileSync(filename, "utf8")
    var fileOperationName = null;

    var ast = graphql.parse(fileOperationBody)
    var visitor = {
      OperationDefinition: {
        enter: function(node) {
          if (fileOperationName) {
            throw new Error("Found multiple operations in " + filename + ": " + fileOperationName + ", " + node.name + ". Files must contain only one operation")
          } else {
            fileOperationName = node.name.value
          }
        },
        leave: function(node) {
          if (addTypename) { addTypenameToSelectionSet(node.selectionSet, true); }
        }
      },
      FragmentDefinition: {
        leave: function(node) {
          if (addTypename) { addTypenameToSelectionSet(node.selectionSet, true); }
        }
      }
    }
    graphql.visit(ast, visitor)

    return {
      // populate alias later, when hashFunc is available
      alias: null,
      name: fileOperationName,
      body: graphql.print(ast),
    }
  })
}

module.exports = prepareIsolatedFiles
