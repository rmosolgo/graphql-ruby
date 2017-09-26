import fs from 'fs';
import { parse } from 'graphql';
import { print, visit } from 'graphql/language';
import addTypenameToSelectionSet from './addTypenameToSelectionSet';

// Return a new AST which contains only `definitionNames`
function extractDefinitions(ast, definitionNames) {
  const removeDefinitionNode = (node) => {
    if (definitionNames.indexOf(node.name.value) === -1) {
      return null;
    }
    return node;
  };
  const visitor = {
    OperationDefinition: removeDefinitionNode,
    FragmentDefinition: removeDefinitionNode,
  };

  const newAST = visit(ast, visitor);
  return newAST;
}

/**
 * Take a whole bunch of GraphQL in one big string
 * and validate it, especially:
 *
 * - operation names are unique
 * - fragment names are unique
 *
 * Then, split each operation into a free-standing document,
 * so it has all the fragments it needs.
 */

function prepareProject(filenames, addTypename) {
  let allGraphQL = '';
  filenames.forEach((filename) => {
    allGraphQL += fs.readFileSync(filename);
  });

  const ast = parse(allGraphQL);

  // This will contain { name: [name, name] } pairs
  const definitionDependencyNames = {};
  const allOperationNames = [];
  let currentDependencyNames = null;

  // When entering a fragment or operation,
  // start recording its dependencies
  const enterDefinition = (node) => {
    const definitionName = node.name.value;
    if (definitionDependencyNames[definitionName]) {
      /* eslint-disable max-len */
      throw new Error(`Found duplicate definition name: ${definitionName}, fragment & operation names must be unique to sync`);
      /* eslint-enable max-len */
    } else {
      /* eslint-disable no-multi-assign */
      currentDependencyNames = definitionDependencyNames[definitionName] = [];
      /* eslint-enable no-multi-assign */
    }
  };
  // When leaving, clean up, just in case
  const leaveDefinition = () => {
    currentDependencyNames = null;
  };

  const visitor = {
    OperationDefinition: {
      enter(node) {
        enterDefinition(node);
        allOperationNames.push(node.name.value);
      },
      leave(node) {
        if (addTypename) { addTypenameToSelectionSet(node.selectionSet, true); }
        return leaveDefinition;
      },
    },
    FragmentDefinition: {
      enter: enterDefinition,
      leave(node) {
        if (addTypename) { addTypenameToSelectionSet(node.selectionSet, true); }
        return leaveDefinition;
      },
    },
    // When entering a fragment spread, register it as a
    // dependency of its context
    FragmentSpread: {
      enter(node) {
        currentDependencyNames.push(node.name.value);
      },
    },
  };

  // Find the dependencies, build the accumulator
  visit(ast, visitor);

  // For each operation, build a separate document of that operation and its deps
  // then print the new document to a string
  const operations = allOperationNames.map((operationName) => {
    const visitedDepNames = [];
    const depNamesToVisit = [operationName];

    let depName;
    while (depNamesToVisit.length > 0) {
      depName = depNamesToVisit.shift();
      visitedDepNames.push(depName);
      definitionDependencyNames[depName].forEach((nextDepName) => {
        if (visitedDepNames.indexOf(nextDepName) === -1) {
          depNamesToVisit.push(nextDepName);
        }
      });
    }
    const newAST = extractDefinitions(ast, visitedDepNames);

    return {
      name: operationName,
      body: print(newAST),
      alias: null, // will be filled in later, when hashFunc is available
    };
  });

  return operations;
}


module.exports = prepareProject;
