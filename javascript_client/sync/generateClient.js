var sendPayload = require("./sendPayload")
var prepareRelay = require("./prepareRelay")

var generateApolloJS = require("./outfileGenerators/apolloJS")
var generateJson = require("./outfileGenerators/json")

var APOLLO_JS_TYPE = "apollo-js";
var JSON_TYPE = "json";

var generators = {
  [APOLLO_JS_TYPE]: generateApolloJS,
  [JSON_TYPE]: generateJson,
};

/**
 * Given a map of { name => alias } pairs, generate outfile based on type.
 * @param {String} clientName - the client ID that this map belongs to
 * @param {Object} nameToAlias - `name => alias` pairs
 * @param {String} type - the outfile's type
 * @return {String} generated outfile code
*/
function generateClient(clientName, nameToAlias, type) {
  if (!clientName) {
    throw new Error("Client name is required to generate a persisted alias lookup map");
  }

  // Build up the map
  var keyValuePairs = "{"
  keyValuePairs += Object.keys(nameToAlias).map(function(operationName) {
    persistedAlias = nameToAlias[operationName]
    return "\n  \"" + operationName + "\": \"" + persistedAlias + "\""
  }).join(",")
  keyValuePairs += "\n}"

  generateOutfile = generators[type || APOLLO_JS_TYPE];

  if (!generateOutfile) {
    throw new Error("Unknown generator type " + type + " encountered for generating the outFile");
  }

  return generateOutfile(type, clientName, keyValuePairs);
}

module.exports = {
  generateClient,
  APOLLO_JS_TYPE,
  JSON_TYPE,
}
