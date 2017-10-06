/* eslint-disable no-redeclare, no-param-reassign, prefer-promise-reject-errors */
const http = require('http');
const url = require('url');
const crypto = require('crypto');

/**
 * Use HTTP POST to send this payload to the endpoint.
 *
 * Override this function with `options.send` to use custom auth.
 *
 * @private
 * @param {Object} payload - JS object to be posted as form data
 * @param {String} options.url - Target URL
 * @param {String} options.secret - (optional) used for HMAC header if provided
 * @param {String} options.client - (optional) used for HMAC header if provided
 * @return {Promise}
*/

function sendPayload(payload, options) {
  const syncUrl = options.url;
  const key = options.secret;
  const clientName = options.client;
  // Prepare JS object as form data
  const postData = JSON.stringify(payload);

  // Get parts of URL for request options
  const parsedURL = url.parse(syncUrl);
  // Prep options for HTTP request
  options = {
    hostname: parsedURL.hostname,
    port: parsedURL.port || '80',
    path: parsedURL.path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(postData),
    },
  };

  // If an auth key was provided, add a HMAC header
  let authDigest = null;
  if (key) {
    authDigest = crypto.createHmac('sha256', key)
      .update(postData)
      .digest('hex');
    options.headers.Authorization = `GraphQL::Pro ${clientName} ${authDigest}`;
  }

  const promise = new Promise(((resolve, reject) => {
    // Make the request,
    // hook up response handler
    const req = http.request(options, (res) => {
      res.setEncoding('utf8');
      const status = res.statusCode;
      // 422 gets special treatment because
      // the body has error messages
      if (status > 299 && status !== 422) {
        reject(`  Server responded with ${res.statusCode}`);
      }
      // Print the response from the server
      res.on('data', (chunk) => {
        resolve(chunk);
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    // Send the data, fire the request
    req.write(postData);
    req.end();
  }));

  return promise;
}


module.exports = sendPayload;
