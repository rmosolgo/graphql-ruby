// TODO:
// - end-to-end test
// - extract update code, inject it as a function?
function createAblyHandler(options) {
  var ably = options.ably
  var operations = options.operations
  var fetchOperation = options.fetchOperation
  return function (operation, variables, cacheConfig, observer) {
    var channelName, channel
    // POST the subscription like a normal query
    fetchOperation(operation, variables, cacheConfig).then(function(response) {
      channelName = response.headers.get("X-Subscription-ID")
      channel = ably.channels.get(channelName)
      // Register presence, so that we can detect empty channels and clean them up server-side
      if (ably.auth.clientId) {
        channel.presence.enter("subscribed")
      } else {
        channel.presence.enterClient("graphql-subscriber", "subscribed")
      }
      // When you get an update from ably, give it to Relay
      channel.subscribe("update", function(message) {
        // TODO Extract this code
        // When we get a response, send the update to `observer`
        var payload = message.data
        var result = payload.result
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
      })
    })
    return {
      dispose: function() {
        channel.presence.leaveClient()
        channel.unsubscribe()
      }
    }
  }
}

export default createAblyHandler
