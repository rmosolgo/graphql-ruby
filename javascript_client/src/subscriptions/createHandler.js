import createActionCableHandler from "./createActionCableHandler";
import createPusherHandler from "./createPusherHandler";
import createAblyHandler from "./createAblyHandler";

/**
 * Transport-agnostic wrapper for Relay Modern subscription handlers.
 * @example Add ActionCable subscriptions
 *   var subscriptionHandler = createHandler({
 *     cable: cable,
 *     operations: OperationStoreClient,
 *   })
 *   var network = Network.create(fetchQuery, subscriptionHandler)
 * @param {ActionCable.Consumer} options.cable - A consumer from `.createConsumer`
 * @param {Pusher} options.pusher - A Pusher client
 * @param {Ably.Realtime} options.ably - An Ably client
 * @param {OperationStoreClient} options.operations - A generated `OperationStoreClient` for graphql-pro's OperationStore
 * @return {Function} A handler for a Relay Modern network
*/
function createHandler(options) {
  if (!options) {
    options = {}
  }
  var handler
  if (options.cable) {
    handler = createActionCableHandler(options.cable, options.operations)
  } else if (options.pusher) {
    handler = createPusherHandler(options)
  } else if (options.ably) {
    handler = createAblyHandler(options)
  }
  return handler
}

export default createHandler
