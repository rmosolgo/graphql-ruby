var fs = require("fs")
var graphql = require("graphql")

/**
 * Read a bunch of GraphQL files and treat them as islands.
 * Don't join any fragments from other files.
 * Don't make assertions about name uniqueness.
 *
 */
function prepareIsolatedFiles(filenames) {
  return filenames.map(function(filename) {
    var fileOperationBody = fs.readFileSync(filename, "utf8")
    var fileOperationDocument = graphql.parse(fileOperationBody)

    // Find one and only one operation name in the file
    var fileOperationName = null
    fileOperationDocument.definitions.forEach(function(definition) {
      if (definition.kind === "OperationDefinition") {
        if (fileOperationName) {
          throw new Error("Found multiple operations in " + filename + ": " + fileOperationName + ", " + definition.name  + ". Files must contain only one operation")
        } else {
          fileOperationName = definition.name.value
        }
      }
    })

    return {
      // populate alias later, when hashFunc is available
      alias: null,
      name: fileOperationName,
      body: fileOperationBody,
    }
  })
}

module.exports = prepareIsolatedFiles
