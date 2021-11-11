import ActionCable from 'actioncable'
import GraphqlWs from 'graphql-ws'
import GraphqlWsClient from './GraphqlWsClient'

/**
 * Create a Relay Modern-compatible subscription handler.
 *
 * @param {ActionCable.Consumer} cable - An ActionCable consumer from `.createConsumer`
 * @param {String} channelName - ActionCable Channel name. Defaults to "GraphqlChannel"
 * @param {OperationStoreClient} operations - A generated OperationStoreClient for graphql-pro's OperationStore
 * @return {Function}
 */
interface ActionCableGraphqlWsClientOptions {
  cable: ActionCable.Cable
  channelName: string
  operations?: { getOperationId: Function}
  // connectionParams: ConnectionParams
}

const getChannelId = () => Math.round(Date.now() + Math.random() * 100000).toString(16) // TODO: extract

interface ChannelNameWithParams extends ActionCable.ChannelNameWithParams {
  channel: string
  channelId: string
}

class ActionCableGraphqlWsClient extends GraphqlWsClient {
  cable: ActionCable.Cable
  actionCableChannel: ActionCable.Channel
  cleanup: () => void
  // operations // TODO:

  constructor(options: ActionCableGraphqlWsClientOptions) {
    super()

    this.cable = options.cable
    const channelNameWithParams: ChannelNameWithParams = {
      channel: options.channelName || 'GraphqlChannel',
      channelId: getChannelId()
    }

    this.actionCableChannel = this.cable.subscriptions.create(channelNameWithParams, {
      connected: this._action_cable_connected,
      disconnected: this._action_cable_disconnected,
      received: this._action_cable_received
    })
    this.cleanup = () => { /* TODO */}
  }

  on(event: GraphqlWs.Event) {
    switch (event) {
      case 'connecting':
        break
      case 'opened':
        break
      case 'connected':
        break
      case 'ping':
        break
      case 'pong':
        break
      case 'message':
        break
      case 'closed':
        break
      case 'error':
        break
    }
    return () => {}
  }

  subscribe(payload: GraphqlWs.SubscribePayload, sink: GraphqlWs.Sink) {
    return this.cleanup
  }

  dispose() {
    return this.cleanup()
  }

  _connect() {

  }

  _action_cable_connected() {
    // TODO
  }

  _action_cable_disconnected() {
    // TODO
  }

  _action_cable_received() {
    // TODO
  }
}

export default ActionCableGraphqlWsClient
