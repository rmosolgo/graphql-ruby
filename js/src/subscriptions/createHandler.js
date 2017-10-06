const createActionCableHandler = require('./createActionCableHandler');
/**
 * Transport-agnostic wrapper for Relay Modern subscription handlers.
 * @example Add ActionCable subscriptions
 *   var subscriptionHandler = createHandler({
 *     cable: cable,
 *     operations: OperationStoreClient,
 *   })
 *   var network = Network.create(fetchQuery, subscriptionHandler)
 * @param {ActionCable.Consumer} options.cable - A consumer from `.createConsumer`
 * @param {OperationStoreClient} options.operations - A generated `OperationStoreClient` for graphql-pro's
 * OperationStore
 * @return {Function} A handler for a Relay Modern network
*/
function createHandler(options = {}) {
  let handler;
  if (options.cable) {
    handler = createActionCableHandler(options.cable, options.operations);
  }
  return handler;
}

module.exports = createHandler;
