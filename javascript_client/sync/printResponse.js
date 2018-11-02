/**
 * Given JSON from the OperationStore server,
 * Send a human-friendly status update to the terminal
*/
function printResponse(response, operations, logger) {
  var aliasToNameMap = {}
  operations.forEach(function(op) {
    aliasToNameMap[op.alias] = op.name
  })

  var failed = response.failed.length
  // These might get overriden for status output
  var notModified = response.not_modified.length
  var added = response.added.length
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
    for (failedOperationAlias in response.errors) {
      failedOperationName = aliasToNameMap[failedOperationAlias]
      logger.error("  " + failedOperationName + ":")
      errors = response.errors[failedOperationAlias]
      errors.forEach(function(errMessage) {
        logger.error("    " + logger.colorize("red", "✘") + " " + errMessage)
      })
    }
  }
}

module.exports = printResponse
