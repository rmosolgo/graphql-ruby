import Pubnub from "pubnub"
interface PubnubHandlerOptions {
  pubnub: Pubnub,
  fetchOperation: Function
}

function createPubnubHandler(options: PubnubHandlerOptions) {
  var pubnub = options.pubnub
  var handlersBySubscriptionId: { [key: string]: Function } = {}
  pubnub.addListener({
    message: (message) => {
      const subscriptionChannel = message.channel
      const handler = handlersBySubscriptionId[subscriptionChannel]
      if (handler) {
        // Send along { result: {...}, more: true|false }
        handler(message.message)
      }
    }
  })
  var fetchOperation = options.fetchOperation
  return function (operation: object, variables: object, cacheConfig: object, observer: { onNext: Function, onError: Function, onCompleted: Function}) {
    var channelName: string
    // POST the subscription like a normal query
    fetchOperation(operation, variables, cacheConfig).then(function(response: { headers: { get: Function } }) {
      channelName = response.headers.get("X-Subscription-ID")
      handlersBySubscriptionId[channelName] = function(payload: { result: { data: object, errors: object[] }, more: Boolean}) {
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
      }
      pubnub.subscribe({channels: [channelName]})
    })
    return {
      dispose: function() {
        delete handlersBySubscriptionId[channelName]
        pubnub.unsubscribe({channels: [channelName]})
      }
    }
  }
}

export {
  createPubnubHandler,
  PubnubHandlerOptions
}
