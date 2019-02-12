var sync = require("./sync")
var generateClient = require("./generateClient").generateClient

module.exports = {
  sync: sync,
  generateClient: generateClient,
}
