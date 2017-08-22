function Logger(isQuiet) {
  this.isQuiet = isQuiet
}

Logger.prototype.log = function() {
  this.isQuiet ? null : console.log.apply(console, arguments)
}

Logger.prototype.error = function() {
  this.isQuiet ? null : console.error.apply(console, arguments)
}

var colors = {
  yellow:   "\x1b[33m",
  red:      "\x1b[31m",
  green:    "\x1b[32m",
  blue:     "\x1b[34m",
  magenta:  "\x1b[35m",
  cyan:     "\x1b[36m",
  reset:    "\x1b[0m",
  bright:   "\x1b[1m",
  dim:      "\x1b[2m",
}

Logger.prototype.colorize = function(color, text) {
  var prefix = colors[color]
  if (!prefix) {
    throw new Error("No color named: " + color)
  }
  return prefix + text + colors.reset
}

function addColorizeShortcut(color) {
  Logger.prototype[color] = function(text) {
    return this.colorize(color, text)
  }
}
var colorName
for (colorName in colors) {
  addColorizeShortcut(colorName)
}

module.exports = Logger
