var md5 = require("./md5")
var sendPayload = require("./sendPayload")
var prepareRelay = require("./prepareRelay")
var prepareIsolatedFiles = require("./prepareIsolatedFiles")
var prepareProject = require("./prepareProject")
var { generateClient } = require("./generateClient")
var printResponse = require("./printResponse")
var Logger = require("./logger")

var glob = require("glob")
var fs = require("fs")

/**
 * Find `.graphql` files in `path`,
 * then prepare them & send them to the configured endpoint.
 *
 * @param {Object} options
 * @param {String} options.path - A glob to recursively search for `.graphql` files (Default is `./`)
 * @param {String} options.secret - HMAC-SHA256 key which must match the server secret (default is no encryption)
 * @param {String} options.url - Target URL for sending prepared queries
 * @param {String} options.mode - If `"file"`, treat each file separately. If `"project"`, concatenate all files and extract each operation. If `"relay"`, treat it as relay-compiler output
 * @param {Boolean} options.addTypename - Indicates if the "__typename" field are automatically added to your queries
 * @param {String} options.outfile - Where the generated code should be written
 * @param {String} options.outfileType - The type of the generated code (i.e., json, apollo-js)
 * @param {String} options.client - the Client ID that these operations belong to
 * @param {Function} options.send - A function for sending the payload to the server, with the signature `options.send(payload)`. (Default is an HTTP `POST` request)
 * @param {Function} options.hash - A custom hash function for query strings with the signature `options.hash(string) => digest` (Default is `md5(string) => digest`)
 * @return {void}
*/
function sync(options) {
  if (!options) {
    options = {}
  }
  var logger = new Logger(options.quiet)

  var url = options.url
  if (!url) {
    throw new Error("URL must be provided for sync")
  }
  var graphqlGlob = options.path || "./"
  var hashFunc = options.hash || md5
  var encryptionKey = options.secret
  if (encryptionKey) {
    logger.log("Authenticating with HMAC")
  }
  var sendFunc = options.send || sendPayload
  var filesMode = options.mode || (graphqlGlob.indexOf("__generated__") > -1 ? "relay" : "project")

  var outfile
  if (options.outfile) {
    outfile = options.outfile
  } else if (fs.existsSync("src")) {
    outfile = "src/OperationStoreClient.js"
  } else {
    outfile = "OperationStoreClient.js"
  }

  var clientName = options.client
  if (!clientName) {
    throw new Error("Client name must be provided for sync")
  }

  // Check for file ext already, add it if missing
  var containsFileExt = graphqlGlob.indexOf(".graphql") > -1 || graphqlGlob.indexOf(".gql") > -1
  if (!containsFileExt) {
    graphqlGlob = graphqlGlob + "**/*.graphql*"
  }

  var payload = {
    operations: []
  }

  var filenames = glob.sync(graphqlGlob, {})

  if (filesMode == "relay") {
    payload.operations = prepareRelay(filenames)
  } else {
    if (filesMode === "file") {
      payload.operations = prepareIsolatedFiles(filenames, options.addTypename)
    } else if (filesMode === "project") {
      payload.operations = prepareProject(filenames, options.addTypename)
    } else {
      throw new Error("Unexpected mode: " + filesMode)
    }
    // Update the operations with the hash of the body
    payload.operations.forEach(function(op) {
      op.alias = hashFunc(op.body)
    })
  }

  if (payload.operations.length === 0) {
    logger.log("No operations found in " + graphqlGlob + ", not syncing anything")
  } else {
    logger.log("Syncing " + payload.operations.length + " operations to " + logger.bright(url) + "...")

    var writeArtifacts = function(response) {
      var nameToAliasMap = {}
      var aliasToNameMap = {}
      payload.operations.forEach(function(op) {
        nameToAliasMap[op.name] = op.alias
        aliasToNameMap[op.alias] = op.name
      })

      var responseData

      if (response) {
        try {
          responseData = JSON.parse(response)
          printResponse(responseData, aliasToNameMap, logger)
          if (responseData.failed.length) {
            return false
          }
        } catch (err) {
          logger.log("Failed to print sync result:", err)
        }
      }

      var generatedCode = generateClient(clientName, nameToAliasMap, options.outfileType)
      logger.log("Generating client module in " + logger.colorize("bright", outfile) + "...")
      fs.writeFileSync(outfile, generatedCode, "utf8")
      logger.log(logger.green("✓ Done!"))
    }

    var sendOpts = {
      url: url,
      client: clientName,
      secret: encryptionKey,
    }
    var maybePromise = sendFunc(payload, sendOpts)

    if (maybePromise instanceof Promise) {
      return maybePromise.then(writeArtifacts).catch(function(err) {
        logger.error(logger.colorize("red", "Sync failed:"))
        logger.error(err)
        return false
      })
    } else {
      return writeArtifacts()
    }
  }
}

module.exports = sync
