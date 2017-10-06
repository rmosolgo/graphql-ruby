const md5 = require('./md5');
const sendPayload = require('./sendPayload');
const prepareRelay = require('./prepareRelay');
const prepareIsolatedFiles = require('./prepareIsolatedFiles');
const prepareProject = require('./prepareProject');
const generateClient = require('./generateClient');
const printResponse = require('./printResponse');
const Logger = require('./logger');

const glob = require('glob');
const fs = require('fs');

/**
 * Find `.graphql` files in `path`,
 * then prepare them & send them to the configured endpoint.
 *
 * @param {Object} options
 * @param {String} options.path - A glob to recursively search for `.graphql` files (Default is `./`)
 * @param {String} options.secret - HMAC-SHA256 key which must match the server secret (default is no encryption)
 * @param {String} options.url - Target URL for sending prepared queries
 * @param {String} options.mode - If `"file"`, treat each file separately. If `"project"`, concatenate all files and
 * extract each operation. If `"relay"`, treat it as relay-compiler output
 * @param {Boolean} options.addTypename - Indicates if the "__typename" field are automatically added to your queries
 * @param {String} options.outfile - Where the generated code should be written
 * @param {String} options.client - the Client ID that these operations belong to
 * @param {Function} options.send - A function for sending the payload to the server, with the signature
 * `options.send(payload)`. (Default is an HTTP `POST` request)
 * @param {Function} options.hash - A custom hash function for query strings with the signature `options.hash(string)
 *  => digest` (Default is `md5(string) => digest`)
 * @return {void}
*/
function sync(options = {}) {
  const logger = new Logger(options.quiet);

  const { url } = options;
  if (!url) {
    throw new Error('URL must be provided for sync');
  }
  let graphqlGlob = options.path || './';
  const hashFunc = options.hash || md5;
  const encryptionKey = options.secret;
  if (encryptionKey) {
    logger.log('Authenticating with HMAC');
  }
  const sendFunc = options.send || sendPayload;
  const filesMode = options.mode || (graphqlGlob.indexOf('__generated__') > -1 ? 'relay' : 'project');

  let outfile;
  if (options.outfile) {
    /* eslint-disable prefer-destructuring */
    outfile = options.outfile;
    /* eslint-enable prefer-destructuring */
  } else if (fs.existsSync('src')) {
    outfile = 'src/OperationStoreClient.js';
  } else {
    outfile = 'OperationStoreClient.js';
  }

  const clientName = options.client;
  if (!clientName) {
    throw new Error('Client name must be provided for sync');
  }

  // Check for file ext already, add it if missing
  const containsFileExt = graphqlGlob.indexOf('.graphql') > -1 || graphqlGlob.indexOf('.gql') > -1;
  if (!containsFileExt) {
    graphqlGlob += '**/*.graphql*';
  }

  const payload = {
    operations: [],
  };

  const filenames = glob.sync(graphqlGlob, {});

  if (filesMode === 'relay') {
    payload.operations = prepareRelay(filenames);
  } else {
    if (filesMode === 'file') {
      payload.operations = prepareIsolatedFiles(filenames, options.addTypename);
    } else if (filesMode === 'project') {
      payload.operations = prepareProject(filenames, options.addTypename);
    } else {
      throw new Error(`Unexpected mode: ${filesMode}`);
    }
    // Update the operations with the hash of the body
    payload.operations.forEach((op) => {
      /* eslint-disable no-param-reassign */
      op.alias = hashFunc(op.body);
      /* eslint-enable no-param-reassign */
    });
  }

  if (payload.operations.length === 0) {
    logger.log(`No operations found in ${graphqlGlob}, not syncing anything`);
  } else {
    logger.log(`Syncing ${payload.operations.length} operations to ${logger.bright(url)}...`);

    const writeArtifacts = (response) => {
      const nameToAliasMap = {};
      const aliasToNameMap = {};
      payload.operations.forEach((op) => {
        nameToAliasMap[op.name] = op.alias;
        aliasToNameMap[op.alias] = op.name;
      });

      let responseData;

      if (response) {
        try {
          responseData = JSON.parse(response);
          printResponse(responseData, aliasToNameMap, logger);
          if (responseData.failed.length) {
            return false;
          }
        } catch (err) {
          logger.log('Failed to print sync result:', err);
        }
      }

      const generatedCode = generateClient(clientName, nameToAliasMap);
      logger.log(`Generating client module in ${logger.colorize('bright', outfile)}...`);
      fs.writeFileSync(outfile, generatedCode, 'utf8');
      logger.log(logger.green('✓ Done!'));

      return null;
    };

    const sendOpts = {
      url,
      client: clientName,
      secret: encryptionKey,
    };
    const maybePromise = sendFunc(payload, sendOpts);

    if (maybePromise instanceof Promise) {
      return maybePromise.then(writeArtifacts).catch((err) => {
        logger.error(logger.colorize('red', 'Sync failed:'));
        logger.error(err);
        return false;
      });
    }
    return writeArtifacts();
  }

  return null;
}

module.exports = sync;
