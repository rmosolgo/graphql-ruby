var sync = require("./index")
var generateClient = require("./generateClient").generateClient

module.exports = {
  sync: sync,
  generateClient: generateClient,
}
