var sync = require("./sync")
var generateClient = require("./sync/generateClient").generateClient

module.exports = {
  sync: sync,
  generateClient: generateClient,
}
