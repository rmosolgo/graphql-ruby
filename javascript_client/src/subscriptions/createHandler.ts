import { createActionCableHandler, ActionCableHandlerOptions } from "./createActionCableHandler"
import { createPusherHandler, PusherHandlerOptions } from "./createPusherHandler"
import { createAblyHandler, AblyHandlerOptions } from "./createAblyHandler"
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
function createHandler(options: ActionCableHandlerOptions | PusherHandlerOptions | AblyHandlerOptions) {
  if (!options) {
    return null
  }
  var handler
  if ((options as ActionCableHandlerOptions).cable) {
    handler = createActionCableHandler(options as ActionCableHandlerOptions)
  } else if ((options as PusherHandlerOptions).pusher) {
    handler = createPusherHandler(options as PusherHandlerOptions)
  } else if ((options as AblyHandlerOptions).ably) {
    handler = createAblyHandler(options as AblyHandlerOptions)
  }
  return handler
}

export default createHandler
