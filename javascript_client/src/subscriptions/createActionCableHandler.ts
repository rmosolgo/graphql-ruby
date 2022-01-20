import type { Consumer } from "@rails/actioncable"

/**
 * Create a Relay Modern-compatible subscription handler.
 *
 * @param {ActionCable.Consumer} cable - An ActionCable consumer from `.createConsumer`
 * @param {OperationStoreClient} operations - A generated OperationStoreClient for graphql-pro's OperationStore
 * @return {Function}
*/
interface ActionCableHandlerOptions {
  cable: Consumer
  operations?: { getOperationId: Function}
}

function createActionCableHandler(options: ActionCableHandlerOptions) {
  return function (operation: { text: string, name: string}, variables: object, _cacheConfig: object, observer: {onError: Function, onNext: Function, onCompleted: Function}) {
    // unique-ish
    var channelId = Math.round(Date.now() + Math.random() * 100000).toString(16)
    var cable = options.cable
    var operations = options.operations

    // Register the subscription by subscribing to the channel
    const channel = cable.subscriptions.create({
      channel: "GraphqlChannel",
      channelId: channelId,
    }, {
      connected: function() {
        var channelParams: object
        // Once connected, send the GraphQL data over the channel
        // Use the stored operation alias if possible
        if (operations) {
          channelParams = {
            variables: variables,
            operationName: operation.name,
            operationId: operations.getOperationId(operation.name)
          }
        } else {
          channelParams = {
            variables: variables,
            operationName: operation.name,
            query: operation.text
          }
        }
        channel.perform('send', channelParams)
        channel.perform("execute", channelParams)
      },
      // This result is sent back from ActionCable.
      received: function(payload: { result: { errors: any[], data: object }, more: boolean}) {
        // When we get a response, send the update to `observer`
        const result = payload.result
        if (result && result.errors) {
          // What kind of error stuff belongs here?
          observer.onError(result.errors)
        } else if (result) {
          observer.onNext({data: result.data})
        }
        if (!payload.more) {
          // Subscription is finished
          observer.onCompleted()
        }
      }
    })

    // Return an object for Relay to unsubscribe with
    return {
      dispose: function() {
        channel.unsubscribe()
      }
    }
  }
}

export {
  createActionCableHandler,
  ActionCableHandlerOptions
}
