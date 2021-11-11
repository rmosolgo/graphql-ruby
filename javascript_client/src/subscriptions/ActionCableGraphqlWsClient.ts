import ActionCable from 'actioncable'
import assert from 'assert'
import GraphqlWs from 'graphql-ws'
import { ActionCableUtil } from '../utils/ActionCableUtil'
import GraphqlWsClient from './GraphqlWsClient'

export interface ActionCableGraphqlWsClientOptions {
  /** An ActionCable consumer from `.createConsumer` */
  cable: ActionCable.Cable
  /** ActionCable Channel name. Defaults to "GraphqlChannel" */
  channelName: string
  /** A generated OperationStoreClient for graphql-pro's OperationStore */
  operations?: { getOperationId: Function}
  // connectionParams: ConnectionParams
}

interface ChannelNameWithParams extends ActionCable.ChannelNameWithParams {
  channel: string
  channelId: string
}

class ActionCableGraphqlWsClient extends GraphqlWsClient {
  cable: ActionCable.Cable
  channel: ActionCable.Channel
  cleanup: () => void
  sink?: GraphqlWs.Sink
  // operations // TODO:

  constructor(options: ActionCableGraphqlWsClientOptions) {
    super()

    this.cable = options.cable
    const channelNameWithParams: ChannelNameWithParams = {
      channel: options.channelName || 'GraphqlChannel',
      channelId: ActionCableUtil.getUniqueChannelId()
    }

    this.channel = this.cable.subscriptions.create(channelNameWithParams, {
      connected: this.action_cable_connected.bind(this),
      disconnected: this.action_cable_disconnected.bind(this),
      received: this.action_cable_received.bind(this)
    })// TODO: support connectionParams like `ActionCableLink.ts` ?
    this.cleanup = () => {
      this.channel.unsubscribe()
    }
  }

  // TODO: Should we do anything with `event` here ?
  on(_event: GraphqlWs.Event) { return () => {} }

  subscribe(payload: GraphqlWs.SubscribePayload, sink: GraphqlWs.Sink) {
    this.sink = sink
    const {
      operationName,
      query,
      variables,
    } = payload

    const channelParams = {
      variables,
      operationName,
      query
    }

    this.channel.perform('execute', channelParams)
    // TODO: Why another 'send' in `createActionCableHandler` ?
    // this.channel.perform('send', channelParams)

    return this.cleanup
  }

  dispose() {
    return this.cleanup()
  }

  private action_cable_connected() {}

  private action_cable_disconnected() {}

  private action_cable_received(payload: any) {
    assert.ok(this.sink) // subscribe() should have been called first, right ?
    const result = payload.result

    if (result?.errors) {
      this.sink.error(result.errors)
    } else if (result) {
      this.sink.next(result)
    }
    if (!payload.more) {
      this.sink.complete()
    }
  }
}

export default ActionCableGraphqlWsClient
