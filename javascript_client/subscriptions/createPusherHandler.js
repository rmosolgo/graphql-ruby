// TODO:
// - end-to-end test
// - extract update code, inject it as a function?
function createPusherHandler(options) {
  var pusher = options.pusher
  var operations = options.operations
  var fetchOperation = options.fetchOperation
  return function (operation, variables, cacheConfig, observer) {
    var channelName;

    // POST the subscription like a normal query
    fetchOperation(operation, variables, cacheConfig).then(function(response) {
      channelName = response.headers.get("X-Subscription-ID")
      channel = pusher.subscribe(channelName)
      // When you get an update from pusher, give it to Relay
      channel.bind("update", function(payload) {
        // TODO Extract this code
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
      })
    })
    return {
      dispose: function() {
        pusher.unsubscribe(channelName)
      }
    }
  }
}

module.exports = createPusherHandler
