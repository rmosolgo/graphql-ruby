/**
 * The channel operations handler is responsible for sending a payload received from the server
 * to the proper (local) subscription request observer. Without it, a payload won't be routed
 * to the correct observer. Worst case, it would end up being sent to every single subscription
 * request observer and thus limiting subscription functionality to one subscription.
 *
 * The handler is responsible for generating the id internally. And the server must respond with
 * it for the assocated subscription request.
 */
export default class ActionCableChannelOperationsHandler {
  constructor(storedOperations) {
    this.storedOperations = storedOperations;
    this.operations = new Map();
    this.operationIdCounter = 0;
  }

  getOperationId() {
    return String(this.operationIdCounter++);
  }

  getChannelParams(operation, variables) {
    const id = this.getOperationId();

    if (this.storedOperations) {
      return {
        id,
        variables,
        operationId: this.storedOperations.getOperationId(operation.name),
        operationName: operation.name,
      };
    }

    return {
      id,
      variables,
      operationName: operation.name,
      query: operation.text,
    };
  }

  addOperation(subscription, operation, variables, cacheConfig, observer) {
    const channelParams = this.getChannelParams(operation, variables);
    this.operations.set(channelParams.id, {
      operation, variables, cacheConfig, observer,
    });
    subscription.perform('execute', channelParams);

    return {
      dispose: () => {
        this.removeOperation(subscription, channelParams);
      },
    };
  }

  removeOperation(subscription, channelParams) {
    const { id } = channelParams;

    this.operations.delete(id);
    subscription.perform('remove', channelParams);
  }

  removeAllOperations() {
    this.operations.forEach((observer) => {
      observer.onCompleted();
    });
    this.operations.clear();
  }

  processPayload(payload) {
    const { id, result } = payload;

    const { observer } = this.operations.get(id);

    if (!id) {
      observer.onError(new Error('No channel operation id in response'));
    } else if (!observer) {
      observer.onError(new Error(`No observer found for channel operation id ${id}`));
    } else if (result && result.errors) {
      observer.onError(result.errors);
    } else if (result) {
      observer.onNext({ data: result.data });
    }

    if (!payload.more) {
      observer.onCompleted();
    }
  }
}
