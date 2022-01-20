import printer from "graphql/language/printer"
import registry from "./registry"
import type { Consumer } from "@rails/actioncable"

interface ApolloNetworkInterface {
  applyMiddlewares: Function
  query: (req: object) => Promise<any>
  _opts: any
}

class ActionCableSubscriber {
  _cable: Consumer
  _networkInterface: ApolloNetworkInterface

  constructor(cable: Consumer, networkInterface: ApolloNetworkInterface) {
    this._cable = cable
    this._networkInterface = networkInterface
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
  subscribe(request: any, handler: any) {
    var networkInterface = this._networkInterface
    // unique-ish
    var channelId = Math.round(Date.now() + Math.random() * 100000).toString(16)
    var channel = this._cable.subscriptions.create({
      channel: "GraphqlChannel",
      channelId: channelId,
    }, {
      // After connecting, send the data over ActionCable
      connected: function() {
        // applyMiddlewares code is inspired by networkInterface internals
        var opts = Object.assign({}, networkInterface._opts)
        networkInterface
          .applyMiddlewares({request: request, options: opts})
          .then(function() {
            var queryString = request.query ? printer.print(request.query) : null
            var operationName = request.operationName
            var operationId = request.operationId
            var variables = JSON.stringify(request.variables)
            var channelParams = Object.assign({}, request, {
              query: queryString,
              variables: variables,
              operationId: operationId,
              operationName: operationName,
            })
            channel.perform("execute", channelParams)
          })
      },
      // Payload from ActionCable should have at least two keys:
      // - more: true if this channel should stay open
      // - result: the GraphQL response for this result
      received: function(payload) {
        if (!payload.more) {
          registry.unsubscribe(id)
        }
        var result = payload.result
        if (result) {
          handler(result.errors, result.data)
        }
      },
    })
    var id = registry.add(channel)
    return id
  }

  unsubscribe(id: number) {
    registry.unsubscribe(id)
  }
}

export default ActionCableSubscriber
