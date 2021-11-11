import { Cable  } from "actioncable"
import { Sink, SubscribePayload } from "graphql-ws"
import ActionCableGraphqlWsClient, { ActionCableGraphqlWsClientOptions } from "../ActionCableGraphqlWsClient"

describe("ActionCableGraphqlWsClient", () => {
  let log: any[]
  let cable: any
  let cableReceived: Function
  let options: ActionCableGraphqlWsClientOptions
  let query: string
  let subscribePayload: SubscribePayload
  let sink: Sink

  beforeEach(() => {
    log = []
    cable = {
      subscriptions: {
        create: function(channelName: string | object, options: {connected: Function, received: Function}) {
          let channel = channelName
          let params = typeof channel === "object" ? channel : { channel }
          let alreadyConnected = false
          cableReceived = options.received
          let subscription = Object.assign(
            Object.create({
              perform: function(actionName: string, options: object) {
                log.push(["cable perform", { actionName: actionName, options: options }])
              },
              unsubscribe: function() {
                log.push(["cable unsubscribe"])
              }
            }),
            { params },
            options
          )

          subscription.connected = subscription.connected.bind(subscription)
          let received = subscription.received
          subscription.received = function(data: any) {
            if (!alreadyConnected) {
              alreadyConnected = true
              subscription.connected()
            }
            received(data)
          }
          subscription.__proto__.unsubscribe = subscription.__proto__.unsubscribe.bind(subscription)
          return subscription
        }
      }
    }
    options = {
      cable: (cable as unknown) as Cable,
      channelName: 'GraphQLChannel',
      operations: undefined
    }

    query = "subscription { foo { bar } }"

    subscribePayload = {
      operationName: 'myOperationName',
      variables: { a: 1 },
      query: query
    }

    sink = {
      next(value) {
        log.push(["sink next", value])
      },
      error(error) {
        log.push(["sink error", error])
      },
      complete() {
        log.push(["sink complete"])
      }
    }
  })

  it("delegates to the cable", () => {
    const client = new ActionCableGraphqlWsClient(options)

    client.subscribe(subscribePayload, sink)
    cableReceived({ result: { data: null }, more: true })
    cableReceived({ result: { data: "data 1" }, more: true })
    cableReceived({ result: { data: "data 2" }, more: false })

    expect(log).toEqual([
      [
        "cable perform",
        {
          actionName: "execute",
          options: {
            operationName: "myOperationName",
            query: "subscription { foo { bar } }",
            variables: { a: 1 }
          }
        }
      ],
      ["sink next", { data: null} ],
      ["sink next", { data: "data 1"} ],
      ["sink next", { data: "data 2"} ],
      ["sink complete"],
    ])
  })

  it("delegates a manual unsubscribe to the cable", () => {
    const client = new ActionCableGraphqlWsClient(options)

    client.subscribe(subscribePayload, sink)
    cableReceived({ result: { data: null }, more: true })
    cableReceived({ result: { data: "data 1" }, more: true })
    client.dispose()

    expect(log).toEqual([
      [
        "cable perform",
        {
          actionName: "execute",
          options: {
            operationName: "myOperationName",
            query: "subscription { foo { bar } }",
            variables: { a: 1 }
          }
        }
      ],
      ["sink next", { data: null }],
      ["sink next", { data: "data 1" }],
      ["cable unsubscribe"]
    ])
  })
})
