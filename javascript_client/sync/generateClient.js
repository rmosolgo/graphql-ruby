var md5 = require("./md5")
var glob = require("glob")

var prepareRelay = require("./prepareRelay")
var prepareIsolatedFiles = require("./prepareIsolatedFiles")
var prepareProject = require("./prepareProject")

var generateJs = require("./outfileGenerators/js")
var generateJson = require("./outfileGenerators/json")

var JS_TYPE = "js";
var JSON_TYPE = "json";

var generators = {
  [JS_TYPE]: generateJs,
  [JSON_TYPE]: generateJson,
};

/**
 * Generate a JavaScript client module based on local `.graphql` files.
 *
 * See {gatherOperations} and {generateClientCode} for options.
 * @return {String} The generated JavaScript code
*/
function generateClient(options) {
  var payload = gatherOperations(options)
  var generatedCode = generateClientCode(options.client, payload.operations, options.clientType)
  return generatedCode
}

/**
 * Parse files in the specified path and generate an alias for each operation.
 *
 * @param {Object} options
 * @param {String} options.path - A glob to recursively search for `.graphql` files (Default is `./`)
 * @param {String} options.mode - If `"file"`, treat each file separately. If `"project"`, concatenate all files and extract each operation. If `"relay"`, treat it as relay-compiler output
 * @param {Boolean} options.addTypename - Indicates if the "__typename" field are automatically added to your queries
 * @param {String} options.clientType - The type of the generated code (i.e., json, js)
 * @param {String} options.client - the Client ID that these operations belong to
 * @param {Function} options.hash - A custom hash function for query strings with the signature `options.hash(string) => digest` (Default is `md5(string) => digest`)
 * @param {Boolean} options.verbose - If true, print debug output
 * @return {Object} An object whose `operations:` key is an array of operations with name and alias
*/
function gatherOperations(options) {
  var graphqlGlob = options.path || "./"
  var hashFunc = options.hash || md5
  var filesMode = options.mode || (graphqlGlob.indexOf("__generated__") > -1 ? "relay" : "project")
  var addTypename = options.addTypename
  var verbose = options.verbose

  // Check for file ext already, add it if missing
  var containsFileExt = graphqlGlob.indexOf(".graphql") > -1 || graphqlGlob.indexOf(".gql") > -1
  if (!containsFileExt) {
    graphqlGlob = graphqlGlob + "**/*.graphql*"
  }
  var payload = {
    operations: []
  }
  var filenames = glob.sync(graphqlGlob, {})
  if (verbose) {
    console.log("[Sync] glob: ", graphqlGlob)
    console.log("[Sync] " + filenames.length + " files:")
    console.log(filenames.map(function(f) { return "[Sync]   - " + f }).join("\n"))
  }
  if (filesMode == "relay") {
    payload.operations = prepareRelay(filenames)
  } else {
    if (filesMode === "file") {
      payload.operations = prepareIsolatedFiles(filenames, addTypename)
    } else if (filesMode === "project") {
      payload.operations = prepareProject(filenames, addTypename)
    } else {
      throw new Error("Unexpected mode: " + filesMode)
    }
    // Update the operations with the hash of the body
    payload.operations.forEach(function(op) {
      op.alias = hashFunc(op.body)
    })
  }
  return payload
}

/**
 * Given a map of { name => alias } pairs, generate outfile based on type.
 * @param {String} clientName - the client ID that this map belongs to
 * @param {Object} nameToAlias - `name => alias` pairs
 * @param {String} type - the outfile's type
 * @return {String} generated outfile code
*/
function generateClientCode(clientName, operations, type) {
  if (!clientName) {
    throw new Error("Client name is required to generate a persisted alias lookup map");
  }

  var nameToAlias = {}
  operations.forEach(function(op) {
    nameToAlias[op.name] = op.alias
  })

  // Build up the map
  var keyValuePairs = "{"
  keyValuePairs += Object.keys(nameToAlias).map(function(operationName) {
    persistedAlias = nameToAlias[operationName]
    return "\n  \"" + operationName + "\": \"" + persistedAlias + "\""
  }).join(",")
  keyValuePairs += "\n}"

  generateOutfile = generators[type || JS_TYPE];

  if (!generateOutfile) {
    throw new Error("Unknown generator type " + type + " encountered for generating the outFile");
  }

  return generateOutfile(type, clientName, keyValuePairs);
}

module.exports = {
  generateClient,
  generateClientCode,
  gatherOperations,
  JS_TYPE,
  JSON_TYPE,
}
