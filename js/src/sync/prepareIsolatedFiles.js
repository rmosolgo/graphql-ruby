const fs = require('fs');
const graphql = require('graphql');
const addTypenameToSelectionSet = require('./addTypenameToSelectionSet');

/**
 * Read a bunch of GraphQL files and treat them as islands.
 * Don't join any fragments from other files.
 * Don't make assertions about name uniqueness.
 *
 */
function prepareIsolatedFiles(filenames, addTypename) {
  return filenames.map((filename) => {
    const fileOperationBody = fs.readFileSync(filename, 'utf8');
    let fileOperationName = null;

    const ast = graphql.parse(fileOperationBody);
    const visitor = {
      OperationDefinition: {
        enter(node) {
          if (fileOperationName) {
            /* eslint-disable max-len */
            throw new Error(`Found multiple operations in ${filename}: ${fileOperationName}, ${node.name}. Files must contain only one operation`);
            /* eslint-enable max-len */
          } else {
            fileOperationName = node.name.value;
          }
        },
        leave(node) {
          if (addTypename) { addTypenameToSelectionSet(node.selectionSet, true); }
        },
      },
      FragmentDefinition: {
        leave(node) {
          if (addTypename) { addTypenameToSelectionSet(node.selectionSet, true); }
        },
      },
    };
    graphql.visit(ast, visitor);

    return {
      // populate alias later, when hashFunc is available
      alias: null,
      name: fileOperationName,
      body: graphql.print(ast),
    };
  });
}

module.exports = prepareIsolatedFiles;
