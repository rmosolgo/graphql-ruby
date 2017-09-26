const path = require('path');
const fs = require('fs');

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
  const currentDirectory = process.cwd();
  const operations = [];
  filenames.forEach((filename) => {
    // Require the file to get values from the JavaScript code
    const absoluteFilename = path.resolve(currentDirectory, filename);
    /* eslint-disable global-require, import/no-dynamic-require */
    const operation = require(absoluteFilename);
    /* eslint-enable global-require, import/no-dynamic-require */
    const operationBody = operation.text;
    const operationName = operation.name;

    // Search the file for the relayHash
    const textContent = fs.readFileSync(filename, 'utf8');
    let operationAlias = textContent.match(/@relayHash ([a-z0-9]+)/);
    // Only operations get `relayHash`, so
    // skip over generated fragments
    if (operationAlias) {
      /* eslint-disable prefer-destructuring */
      operationAlias = operationAlias[1];
      /* eslint-enable prefer-destructuring */
      operations.push({
        alias: operationAlias,
        name: operationName,
        body: operationBody,
      });
    }
  });

  return operations;
}

module.exports = prepareRelay;
