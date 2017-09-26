const crypto = require('crypto');

// Return the hex-encoded md5 hash of `inputString`
function md5(inputString) {
  return crypto.createHash('md5')
    .update(inputString)
    .digest('hex');
}

module.exports = md5;
