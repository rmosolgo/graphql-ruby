var fs = require("fs")
var graphql = require("graphql")
var addTypenameToSelectionSet = require("./addTypenameToSelectionSet")

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
  if(!filenames.length) { return []; }
  var allGraphQL = ""
  filenames.forEach(function(filename) {
    allGraphQL += fs.readFileSync(filename)
  })

  var ast = graphql.parse(allGraphQL)

  // This will contain { name: [name, name] } pairs
  var definitionDependencyNames = {}
  var allOperationNames = []
  var currentDependencyNames = null

  // When entering a fragment or operation,
  // start recording its dependencies
  var enterDefinition = function(node) {
    var definitionName = node.name.value
    if (definitionDependencyNames[definitionName]) {
      throw new Error("Found duplicate definition name: " + definitionName + ", fragment & operation names must be unique to sync")
    } else {
      currentDependencyNames = definitionDependencyNames[definitionName] = []
    }
  }
  // When leaving, clean up, just in case
  var leaveDefinition = function(node) {
    currentDependencyNames = null
  }

  var visitor = {
    OperationDefinition: {
      enter: function(node) {
        enterDefinition(node)
        allOperationNames.push(node.name.value)
      },
      leave: function(node) {
        if (addTypename) { addTypenameToSelectionSet(node.selectionSet, true) }
        leaveDefinition
      }
    },
    FragmentDefinition: {
      enter: enterDefinition,
      leave: function(node) {
        if (addTypename) { addTypenameToSelectionSet(node.selectionSet, true) }
        leaveDefinition
      }
    },
    // When entering a fragment spread, register it as a
    // dependency of its context
    FragmentSpread: {
      enter: function(node) {
        currentDependencyNames.push(node.name.value)
      }
    }
  }

  // Find the dependencies, build the accumulator
  graphql.visit(ast, visitor)

  // For each operation, build a separate document of that operation and its deps
  // then print the new document to a string
  var operations = allOperationNames.map(function(operationName) {
    var visitedDepNames = []
    var depNamesToVisit = [operationName]

    var depName
    while (depNamesToVisit.length > 0) {
      depName = depNamesToVisit.shift()
      visitedDepNames.push(depName)
      definitionDependencyNames[depName].forEach(function(nextDepName) {
        if (visitedDepNames.indexOf(nextDepName) === -1) {
          depNamesToVisit.push(nextDepName)
        }
      })
    }
    var newAST = extractDefinitions(ast, visitedDepNames)
    return {
      name: operationName,
      body: graphql.print(newAST),
      alias: null, // will be filled in later, when hashFunc is available
    }
  })

  return operations
}


// Return a new AST which contains only `definitionNames`
function extractDefinitions(ast, definitionNames) {
  var removeDefinitionNode = function(node) {
    if (definitionNames.indexOf(node.name.value) === -1) {
      return null
    }
  }
  var visitor = {
    OperationDefinition: removeDefinitionNode,
    FragmentDefinition: removeDefinitionNode,
  }

  var newAST = graphql.visit(ast, visitor)
  return newAST
}

module.exports = prepareProject
