var path = require("path")
var fs = require("fs")

/**
 * Read relay-compiler output
 * and extract info for persisting them & writing a map:
 *
 * - alias: get the relayHash from the header
 * - name: get the name from the JavaScript object
 * - body: get the text from the JavaScript object
 *
 * @param {Array} filenames -  Filenames to read
 * @return {Array} List of operations to persist & write to a map
 */
function prepareRelay(filenames) {
  var currentDirectory = process.cwd()
  var operations = []
  filenames.forEach(function(filename) {
    // Require the file to get values from the JavaScript code
    var absoluteFilename = path.resolve(currentDirectory, filename)
    var operation = require(absoluteFilename)
    var operationBody, operationName
    // Support Relay version ^2.0.0
    if (operation.params) {
      operationBody = operation.params.text
      operationName = operation.params.name
    } else {
      // Support Relay versions < 2.0.0
      operationBody = operation.text
      operationName = operation.name
    }

    // Search the file for the relayHash
    var textContent = fs.readFileSync(filename, "utf8")
    var operationAlias = textContent.match(/@relayHash ([a-z0-9]+)/)
    // Only operations get `relayHash`, so
    // skip over generated fragments
    if (operationAlias) {
      operationAlias = operationAlias[1]
      operations.push({
        alias: operationAlias,
        name: operationName,
        body: operationBody,
      })
    }
  })

  return operations
}

module.exports = prepareRelay
