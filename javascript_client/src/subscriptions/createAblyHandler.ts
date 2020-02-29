import { Realtime, Types } from "ably"
// TODO:
// - end-to-end test
// - extract update code, inject it as a function?

interface AblyHandlerOptions {
  ably: Realtime
  fetchOperation: Function
}

interface ApolloObserver {
  onError: Function
  onNext: Function
  onCompleted: Function
}

function createAblyHandler(options: AblyHandlerOptions) {
  var ably = options.ably
  var fetchOperation = options.fetchOperation
  return function (operation: object, variables: object, cacheConfig: object, observer: ApolloObserver) {
    var channelName
    var channel: Types.RealtimeChannelCallbacks
    // POST the subscription like a normal query
    fetchOperation(operation, variables, cacheConfig).then(function(response: {headers: { get: Function } }) {
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
        if (channel) {
          if (ably.auth.clientId) {
            channel.presence.leave()
          } else {
            channel.presence.leaveClient("graphql-subscriber")
          }
          channel.unsubscribe()
        }
      }
    }
  }
}

export {
  createAblyHandler,
  AblyHandlerOptions
}
