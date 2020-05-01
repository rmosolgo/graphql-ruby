import sendPayload from "./sendPayload"
import { generateClientCode, gatherOperations, ClientOperation } from "./generateClient"
import Logger from "./logger"
import fs from "fs"

interface SyncOptions {
  path?: string,
  relayPersistedOutput?: string,
  apolloAndroidOperationOutput?: string,
  secret?: string
  url: string,
  mode?: string,
  outfile?: string,
  outfileType?: string,
  client: string,
  send?: Function,
  hash?: Function,
  verbose?: boolean,
  quiet?: boolean,
  addTypename?: boolean,
}
/**
 * Find `.graphql` files in `path`,
 * then prepare them & send them to the configured endpoint.
 *
 * @param {Object} options
 * @param {String} options.path - A glob to recursively search for `.graphql` files (Default is `./`)
 * @param {String} options.relayPersistedOutput - A path to a `.json` file from `relay-compiler`'s  `--persist-output` option
 * @param {String} options.secret - HMAC-SHA256 key which must match the server secret (default is no encryption)
 * @param {String} options.url - Target URL for sending prepared queries
 * @param {String} options.mode - If `"file"`, treat each file separately. If `"project"`, concatenate all files and extract each operation. If `"relay"`, treat it as relay-compiler output
 * @param {Boolean} options.addTypename - Indicates if the "__typename" field are automatically added to your queries
 * @param {String} options.outfile - Where the generated code should be written
 * @param {String} options.outfileType - The type of the generated code (i.e., json, js)
 * @param {String} options.client - the Client ID that these operations belong to
 * @param {Function} options.send - A function for sending the payload to the server, with the signature `options.send(payload)`. (Default is an HTTP `POST` request)
 * @param {Function} options.hash - A custom hash function for query strings with the signature `options.hash(string) => digest` (Default is `md5(string) => digest`)
 * @param {Boolean} options.verbose - If true, log debug output
 * @return {Promise} Rejects with an Error or String if something goes wrong. Resolves with the operation payload if successful.
*/
function sync(options: SyncOptions) {
  var logger = new Logger(!!options.quiet)
  var verbose = !!options.verbose
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

  var graphqlGlob = options.path
  var hashFunc = options.hash
  var sendFunc = options.send || sendPayload
  var gatherMode = options.mode
  var clientType = options.outfileType
  if (options.relayPersistedOutput) {
    // relay-compiler has already generated an artifact for us
    var payload: { operations: ClientOperation[] } = { operations: [] }
    var relayOutputText = fs.readFileSync(options.relayPersistedOutput, "utf8")
    var relayOutput = JSON.parse(relayOutputText)
    var operationBody
    for (var hash in relayOutput) {
      operationBody = relayOutput[hash]
      payload.operations.push({
        body: operationBody,
        alias: hash,
      })
    }
  } else if (options.apolloAndroidOperationOutput) {
    // Apollo Android has already generated an artifact (https://www.apollographql.com/docs/android/advanced/persisted-queries/#operationoutputjson)
    var payload: { operations: ClientOperation[] } = { operations: [] }
    var apolloAndroidOutputText = fs.readFileSync(options.apolloAndroidOperationOutput, "utf8")
    var apolloAndroidOutput = JSON.parse(apolloAndroidOutputText)
    var operationData
    // Structure is { operationId => { "name" => "...", "source" => "query { ... } " } }
    for (var operationId in apolloAndroidOutput) {
      operationData = apolloAndroidOutput[operationId]
      payload.operations.push({
        body: operationData.source,
        alias: operationId,
      })
    }

  } else {
    var payload = gatherOperations({
      path: graphqlGlob,
      hash: hashFunc,
      mode: gatherMode,
      addTypename: !!options.addTypename,
      clientType: clientType,
      client: clientName,
      verbose: verbose,
    })
  }

  var outfile: string | null
  if (options.outfile) {
    outfile = options.outfile
  } else if (options.relayPersistedOutput || options.apolloAndroidOperationOutput) {
    // These artifacts have embedded IDs in its generated files,
    // no need to generate an outfile.
    outfile = null
  } else if (fs.existsSync("src")) {
    outfile = "src/OperationStoreClient.js"
  } else {
    outfile = "OperationStoreClient.js"
  }

  return new Promise(function(resolve, reject) {
    if (payload.operations.length === 0) {
      logger.log("No operations found in " + options.path + ", not syncing anything")
      resolve(payload)
      return
    } else {
      logger.log("Syncing " + payload.operations.length + " operations to " + logger.bright(url) + "...")
      var sendOpts = {
        url: url,
        client: clientName,
        secret: encryptionKey,
        verbose: verbose,
      }
      var sendPromise = Promise.resolve(sendFunc(payload, sendOpts))
      return sendPromise.then(function(response) {
        var responseData
        if (response) {
          try {
            responseData = JSON.parse(response)
            var aliasToNameMap: {[key: string] : string | undefined} = {}

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
              var failedOperationAlias: string
              var failedOperationName: string
              var errors
              var allErrors: string[] = []
              for (failedOperationAlias in responseData.errors) {
                failedOperationName = aliasToNameMap[failedOperationAlias] || failedOperationAlias
                logger.error("  " + failedOperationName + ":")
                errors = responseData.errors[failedOperationAlias]
                errors.forEach(function(errMessage: string) {
                  allErrors.push(failedOperationName + ": " + errMessage)
                  logger.error("    " + logger.red("✘") + " " + errMessage)
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

        // Don't generate a new file when we're using relay-comipler's --persist-output
        if (outfile) {
          var generatedCode = generateClientCode(clientName, payload.operations, clientType)
          var finishedPayload = {
            operations: payload.operations,
            generatedCode,
          }
          logger.log("Generating client module in " + logger.colorize("bright", outfile) + "...")
          fs.writeFileSync(outfile, generatedCode, "utf8")
          logger.log(logger.green("✓ Done!"))
          resolve(finishedPayload)
        } else {
          logger.log(logger.green("✓ Done!"))
          resolve(payload)
        }
        return
      }).catch(function(err) {
        logger.error(logger.red("Sync failed:"))
        logger.error(err)
        reject(err)
        return
      })
    }
  })
}

export default sync
