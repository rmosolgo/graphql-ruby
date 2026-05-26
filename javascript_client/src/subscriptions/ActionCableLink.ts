import { ApolloLink, Observable, FetchResult, Operation, NextLink } from "@apollo/client/core"
import type { Consumer } from "@rails/actioncable"
import { print } from "graphql"

type RequestResult = FetchResult<{ [key: string]: any; }, Record<string, any>, Record<string, any>>
type ConnectionParams = object | ((operation: Operation) => object)
type SubscriptionCallbacks = {
  connected?: (args?: { reconnected: boolean }) => void;
  disconnected?: () => void;
  received?: (payload: any) => void;
};

type CreateChannelId = () => string

function createChannelId() {
  // `crypto.randomUUID()` (Web Crypto API) is used because a low-entropy
  // identifier here can collide between simultaneously-created subscriptions,
  // and ActionCable routes incoming payloads by identifier — colliding
  // subscriptions would receive each other's payloads.
  return crypto.randomUUID()
}

class ActionCableLink extends ApolloLink {
  cable: Consumer
  channelName: string
  actionName: string
  connectionParams: ConnectionParams
  callbacks: SubscriptionCallbacks
  createChannelId: CreateChannelId

  constructor(options: {
    cable: Consumer,
    createChannelId?: CreateChannelId,
    channelName?: string,
    actionName?: string,
    connectionParams?: ConnectionParams,
    callbacks?: SubscriptionCallbacks,
  }) {
    super()
    this.cable = options.cable
    this.channelName = options.channelName || "GraphqlChannel"
    this.actionName = options.actionName || "execute"
    this.connectionParams = options.connectionParams || {}
    this.callbacks = options.callbacks || {}
    this.createChannelId = options.createChannelId || createChannelId
  }

  // Interestingly, this link does _not_ call through to `next` because
  // instead, it sends the request to ActionCable.
  request(operation: Operation, _next: NextLink): Observable<RequestResult> {
    return new Observable((observer) => {
      var channelId = this.createChannelId()
      var actionName = this.actionName
      var connectionParams = (typeof this.connectionParams === "function") ?
        this.connectionParams(operation) : this.connectionParams
      var callbacks = this.callbacks
      var channel = this.cable.subscriptions.create(Object.assign({},{
        channel: this.channelName,
        channelId: channelId
      }, connectionParams), {
        connected: function(args?: any) {
          this.perform(
            actionName,
            {
              query: operation.query ? print(operation.query) : null,
              variables: operation.variables,
              // This is added for persisted operation support:
              operationId: (operation as {operationId?: string}).operationId,
              operationName: operation.operationName
            }
          )
          callbacks.connected?.(args)
        },
        received: function(payload) {
          if (payload?.result?.data || payload?.result?.errors) {
            observer.next(payload.result)
          }

          if (!payload.more) {
            observer.complete()
          }
          callbacks.received?.(payload)
        },
        disconnected: function() {
          callbacks.disconnected?.()
        }
      })
      // Make the ActionCable subscription behave like an Apollo subscription
      return Object.assign(channel, {closed: false})
    })
  }
}

export default ActionCableLink
