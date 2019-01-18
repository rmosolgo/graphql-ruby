var printer = require("graphql/language/printer")
var registry = require("./registry")

/**
 * Make a new subscriber for `addGraphQLSubscriptions`
 *
 * @param {Pusher} pusher
*/
function PusherSubscriber(pusher, networkInterface) {
  this._pusher = pusher
  this._networkInterface = networkInterface
  // This is a bit tricky:
  // only the _request_ is passed to the `subscribe` function, s
  // so we have to attach the subscription id to the `request`.
  // However, the request is _not_ available in the afterware function.
  // So:
  // - Add the request to `options` so it's available in afterware
  // - In the afterware, update the request to hold the header value
  // - Finally, in `subscribe`, read the subscription ID off of `request`
  networkInterface.use([{
    applyMiddleware: function({request, options}, next) {
      options.request = request
      next()
    }
  }])
  networkInterface.useAfter([{
    applyAfterware: function({response, options}, next) {
      options.request.__subscriptionId = response.headers.get("X-Subscription-ID")
      next()
    }
  }])
}

// Implement the Apollo subscribe API
PusherSubscriber.prototype.subscribe = function(request, handler) {
  var pusher = this._pusher
  var networkInterface = this._networkInterface
  var subscription = {
    _channelName: null, // set after the successful POST
    unsubscribe: function() {
      pusher.unsubscribe(this._channelName)
    }
  }

  // Send the subscription as a query
  // Get the channel ID from the response headers
  networkInterface.query(request).then(function(executionResult){
    var subscriptionChannel = request.__subscriptionId
    subscription._channelName = subscriptionChannel
    var pusherChannel = pusher.subscribe(subscriptionChannel)
    // When you get an update form Pusher, send it to Apollo
    pusherChannel.bind("update", function(payload) {
      if (!payload.more) {
        registry.unsubscribe(subscription)
      }
      var result = payload.result
      if (result) {
        handler(result.errors, result.data)
      }
    })
  })
  var id = registry.add(subscription)
  return id
}

// Implement the Apollo unsubscribe API
PusherSubscriber.prototype.unsubscribe = function(id) {
  registry.unsubscribe(id)
}

module.exports = PusherSubscriber
