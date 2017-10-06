/**
 * Create a Relay Modern-compatible subscription handler.
 * TODO: how to test this??
 *
 * @param {ActionCable.Consumer} cable - An ActionCable consumer from `.createConsumer`
 * @param {OperationStoreClient} operations - A generated OperationStoreClient for graphql-pro's
 * OperationStore
 * @return {Function}
*/

import ActionCableChannelOperationsHandler from './ActionCableChannelOperationsHandler';

const createActionCableHandler = (cable, storedOperations) => {
  const handler = new ActionCableChannelOperationsHandler(storedOperations);

  const subscription = cable.subscriptions.create({
    channel: 'GraphqlChannel',
  }, {
    disconnected: () => {
      handler.removeAllOperations();
    },
    received: (payload) => {
      handler.processPayload(payload);
    },
  });

  return (operation, variables, cacheConfig, observer) => {
    const disposable = handler.addOperation(subscription, operation, variables, cacheConfig, observer);

    return {
      dispose() {
        disposable.dispose();
      },
    };
  };
}

export default createActionCableHandler;
