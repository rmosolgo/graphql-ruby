const ActionCableSubscriber = require('./ActionCableSubscriber');

/**
 * Modify an Apollo network interface to
 * subscribe an unsubscribe using `cable:`.
 * Based on `addGraphQLSubscriptions` from `subscriptions-transport-ws`.
 *
 * This function assigns `.subscribe` and `.unsubscribe` functions
 * to the provided networkInterface.
 * @example Adding ActionCable subscriptions to a HTTP network interface
 *   // Load ActionCable and create a consumer
 *   var ActionCable = require('actioncable')
 *   var cable = ActionCable.createConsumer()
 *   window.cable = cable
 *
 *   // Load ApolloClient and create a network interface
 *   var apollo = require('apollo-client')
 *   var RailsNetworkInterface = apollo.createNetworkInterface({
 *     uri: '/graphql',
 *     opts: {
 *       credentials: 'include',
 *     },
 *     headers: {
 *       'X-CSRF-Token': $("meta[name=csrf-token]").attr("content"),
 *     }
 *   });
 *
 *   // Add subscriptions to the network interface
 *   var addGraphQLSubscriptions =
 *     require("graphql-ruby-client/subscriptions/addGraphQLSubscriptions")
 *   addGraphQLSubscriptions(RailsNetworkInterface, {cable: cable})
 *
 *   // Optionally, add persisted query support:
 *   var OperationStoreClient = require("./OperationStoreClient")
 *   RailsNetworkInterface.use([OperationStoreClient.apolloMiddleware])
 *
 * @param {Object} networkInterface - an HTTP NetworkInterface
 * @param {ActionCable.Consumer} options.cable - A cable for subscribing with
 * @return {void}
*/
function addGraphQLSubscriptions(networkInterface, options = {}) {
  let subscriber;
  if (options.subscriber) {
    // Right now this is just for testing
    /* eslint-disable prefer-destructuring */
    subscriber = options.subscriber;
    /* eslint-enable prefer-destructuring */
  } else if (options.cable) {
    subscriber = new ActionCableSubscriber(options.cable, networkInterface);
  } else {
    throw new Error('Must provide cable: option');
  }

  const networkInterfaceWithSubscriptions = Object.assign(networkInterface, {
    subscribe(request, handler) {
      const id = subscriber.subscribe(request, handler);
      return id;
    },
    unsubscribe(id) {
      subscriber.unsubscribe(id);
    },
  });
  return networkInterfaceWithSubscriptions;
}

module.exports = addGraphQLSubscriptions;
