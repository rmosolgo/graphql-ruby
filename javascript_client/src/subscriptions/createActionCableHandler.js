/**
 * Create a Relay Modern-compatible subscription handler.
 *
 * @param {ActionCable.Consumer} cable - An ActionCable consumer from `.createConsumer`
 * @param {OperationStoreClient} operations - A generated OperationStoreClient for graphql-pro's OperationStore
 * @return {Function}
*/
function createActionCableHandler(cable, operations) {
  return function (operation, variables, cacheConfig, observer) {
    // unique-ish
    var channelId = Math.round(Date.now() + Math.random() * 100000).toString(16)

    // Register the subscription by subscribing to the channel
    const subscription = cable.subscriptions.create({
      channel: "GraphqlChannel",
      channelId: channelId,
    }, {
      connected: function() {
        // Once connected, send the GraphQL data over the channel
        const channelParams = {
          variables: variables,
          operationName: operation.name,
        }

        // Use the stored operation alias if possible
        if (operations) {
          channelParams.operationId = operations.getOperationId(operation.name)
        } else {
          channelParams.query = operation.text
        }

        this.perform("execute", channelParams)
      },
      received: function(payload) {
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
        subscription.unsubscribe()
      }
    }
  }
}

export default createActionCableHandler
