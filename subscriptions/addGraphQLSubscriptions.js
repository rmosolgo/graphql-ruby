var ActionCableSubscriber = require("./ActionCableSubscriber")

// Modify an Apollo network interface to
// subscribe an unsubscribe using `cable:`.
// Based on `addGraphQLSubscriptions` from `subscriptions-transport-ws`.
//
// This function assigns `.subscribe` and `.unsubscribe` functions
// to the provided networkInterface.
function addGraphQLSubscriptions(networkInterface, options) {
  if (!options) {
    options = {}
  }

  var subscriber
  if (options.subscriber) {
    // Right now this is just for testing
    subscriber = options.subscriber
  } else if (options.cable) {
    subscriber = new ActionCableSubscriber(options.cable, networkInterface)
  } else {
    throw new Error("Must provide cable: option")
  }

  var networkInterfaceWithSubscriptions = Object.assign(networkInterface, {
    subscribe: function(request, handler) {
      var id = subscriber.subscribe(request, handler)
      return id
    },
    unsubscribe(id) {
      subscriber.unsubscribe(id)
    },
  })
  return networkInterfaceWithSubscriptions
}

module.exports = addGraphQLSubscriptions
