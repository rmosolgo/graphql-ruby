var sendPayload = require("./sendPayload")
var prepareRelay = require("./prepareRelay")
var prepareIsolatedFiles = require("./prepareIsolatedFiles")
var prepareProject = require("./prepareProject")
var { generateClientCode, gatherOperations } = require("./generateClient")
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
 * @param {String} options.outfileType - The type of the generated code (i.e., json, js)
 * @param {String} options.client - the Client ID that these operations belong to
 * @param {Function} options.send - A function for sending the payload to the server, with the signature `options.send(payload)`. (Default is an HTTP `POST` request)
 * @param {Function} options.hash - A custom hash function for query strings with the signature `options.hash(string) => digest` (Default is `md5(string) => digest`)
 * @return {Promise} Rejects with an Error or String if something goes wrong. Resolves with the operation payload if successful.
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
  var clientName = options.client
  if (!clientName) {
    throw new Error("Client name must be provided for sync")
  }
  var encryptionKey = options.secret
  if (encryptionKey) {
    logger.log("Authenticating with HMAC")
  }

  var sendFunc = options.send || sendPayload

  var payload = gatherOperations({
    path: options.path,
    hash: options.hash,
    mode: options.mode,
    addTypename: options.addTypename,
    clientType: options.outfileType,
    client: clientName,
  })

  var outfile
  if (options.outfile) {
    outfile = options.outfile
  } else if (fs.existsSync("src")) {
    outfile = "src/OperationStoreClient.js"
  } else {
    outfile = "OperationStoreClient.js"
  }

  return new Promise(function(resolve, reject) {
    if (payload.operations.length === 0) {
      logger.log("No operations found in " + graphqlGlob + ", not syncing anything")
      resolve(payload)
    } else {
      logger.log("Syncing " + payload.operations.length + " operations to " + logger.bright(url) + "...")
      var sendOpts = {
        url: url,
        client: clientName,
        secret: encryptionKey,
      }
      var sendPromise = Promise.resolve(sendFunc(payload, sendOpts))
      return sendPromise.then(function(response) {
        var responseData
        if (response) {
          try {
            responseData = JSON.parse(response)
            var aliasToNameMap = {}

            payload.operations.forEach(function(op) {
              aliasToNameMap[op.alias] = op.name
            })

            var failed = responseData.failed.length
            // These might get overriden for status output
            var notModified = responseData.not_modified.length
            var added = responseData.added.length
            if (failed) {
              // Override these to reflect reality
              notModified = 0
              added = 0
            }

            var addedColor = added ? "green" : "dim"
            logger.log("  " + logger.colorize(addedColor, added + " added"))
            var notModifiedColor = notModified ? "reset" : "dim"

            logger.log("  " + logger.colorize(notModifiedColor, notModified + " not modified"))
            var failedColor = failed ? "red" : "dim"
            logger.log("  " + logger.colorize(failedColor, failed + " failed"))

            if (failed) {
              logger.error("Sync failed, errors:")
              var failedOperationAlias, failedOperationName, errors
              var allErrors = []
              for (failedOperationAlias in responseData.errors) {
                failedOperationName = aliasToNameMap[failedOperationAlias]
                logger.error("  " + failedOperationName + ":")
                errors = responseData.errors[failedOperationAlias]
                errors.forEach(function(errMessage) {
                  allErrors.push(failedOperationName + ": " + errMessage)
                  logger.error("    " + logger.colorize("red", "✘") + " " + errMessage)
                })
              }
              reject("Sync failed: " + allErrors.join(", "))
              return
            }
          } catch (err) {
            logger.log("Failed to print sync result:", err)
            reject(err)
            return
          }
        }

        var generatedCode = generateClientCode(clientName, payload.operations, options.outfileType)
        payload.generatedCode = generatedCode
        logger.log("Generating client module in " + logger.colorize("bright", outfile) + "...")
        fs.writeFileSync(outfile, generatedCode, "utf8")
        logger.log(logger.green("✓ Done!"))
        resolve(payload)
        return
      }).catch(function(err) {
        logger.error(logger.colorize("red", "Sync failed:"))
        logger.error(err)
        reject(err)
        return
      })
    }
  })
}

module.exports = sync
