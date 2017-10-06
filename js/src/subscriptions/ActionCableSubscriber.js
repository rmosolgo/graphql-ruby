/* eslint-disable no-underscore-dangle */
const printer = require('graphql/language/printer');
const registry = require('./registry');

/**
 * Make a new subscriber for `addGraphQLSubscriptions`
 *
 * TODO: How to test this?
 *
 * @param {ActionCable.Consumer} cable ActionCable client
*/
function ActionCableSubscriber(cable, networkInterface) {
  this._cable = cable;
  this._networkInterface = networkInterface;
}

/**
 * Send `request` over ActionCable (`registry._cable`),
 * calling `handler` with any incoming data.
 * Return the subscription so that the registry can unsubscribe it later.
 * @param {Object} registry
 * @param {Object} request
 * @param {Function} handler
 * @return {ID} An ID for unsubscribing
*/
ActionCableSubscriber.prototype.subscribe = function subscribeToActionCable(request, handler) {
  const networkInterface = this._networkInterface;

  const channel = this._cable.subscriptions.create({
    channel: 'GraphqlChannel',
  }, {
    // After connecting, send the data over ActionCable
    connected() {
      const _this = this;
      // applyMiddlewares code is inspired by networkInterface internals
      const opts = Object.assign({}, networkInterface._opts);
      networkInterface
        .applyMiddlewares({ request, options: opts })
        .then(() => {
          const queryString = request.query ? printer.print(request.query) : null;
          const { operationName, operationId } = request;
          const variables = JSON.stringify(request.variables);
          const channelParams = Object.assign({}, request, {
            query: queryString,
            variables,
            operationId,
            operationName,
          });
          // This goes to the #execute method of the channel
          _this.perform('execute', channelParams);
        });
    },
    // Payload from ActionCable should have at least two keys:
    // - more: true if this channel should stay open
    // - result: the GraphQL response for this result
    received(payload) {
      if (!payload.more) {
        registry.unsubscribe(this);
      }
      const { result } = payload;
      if (result) {
        handler(result.errors, result.data);
      }
    },
  });
  const id = registry.add(channel);
  return id;
};

/**
 * End the subscription.
 * @param {ID} id An ID from `.subscribe`
 * @return {void}
*/
ActionCableSubscriber.prototype.unsubscribe = (id) => {
  registry.unsubscribe(id);
};


module.exports = ActionCableSubscriber;
