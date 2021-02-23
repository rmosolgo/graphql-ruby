import ActionCableLink from "../ActionCableLink"
import { parse } from "graphql"
import { Cable } from "actioncable"
import { Operation } from "@apollo/client/core"

describe("ActionCableLink", () => {
  var log: any[]
  var cable: any
  var options: any
  var link: any
  var query: any
  var operation: Operation

  beforeEach(() => {
    log = []
    cable = {
      subscriptions: {
        create: function(_channelName: string, options: {connected: Function, received: Function}) {
          var subscription = Object.assign(
            Object.create({
              perform: function(actionName: string, options: object) {
                log.push(["perform", { actionName: actionName, options: options }])
              },
              unsubscribe: function() {
                log.push(["unsubscribe"])
              }
            }),
            options
          )

          subscription.connected = subscription.connected.bind(subscription)
          subscription.__proto__.unsubscribe = subscription.__proto__.unsubscribe.bind(subscription)
          subscription.connected()
          return subscription
        }
      }
    }
    options = {
      cable: (cable as unknown) as Cable
    }
    link = new ActionCableLink(options)

    query = parse("subscription { foo { bar } }")

    operation = ({
      query: query,
      variables: { a: 1 },
      operationId: "operationId",
      operationName: "operationName"
    } as unknown) as Operation
  })

  it("delegates to the cable", () => {
    var observable = link.request(operation, null as any)

    // unpack the underlying subscription
    var subscription: any = (observable.subscribe(function(result: any) {
      log.push(["received", result])
    }) as any)._cleanup

    subscription.received({
      result: {
        data: null
      },
      more: true
    })

    subscription.received({
      result: {
        data: "data 1"
      },
      more: true
    })

    subscription.received({
      result: {
        data: "data 2"
      },
      more: false
    })

    expect(log).toEqual([
      [
        "perform", {
          actionName: "execute",
          options: {
            query: "subscription {\n  foo {\n    bar\n  }\n}\n",
            variables: { a: 1 },
            operationId: "operationId",
            operationName: "operationName"
          }
        }
      ],
      ["received", { data: "data 1" }],
      ["received", { data: "data 2" }],
      ["unsubscribe"]
    ])
  })

  it("delegates a manual unsubscribe to the cable", () => {
    var observable = link.request(operation, null as any)

    // unpack the underlying subscription
    var subscription: any = (observable.subscribe(function(result: any) {
      log.push(["received", result])
    }) as any)._cleanup

    subscription.received({
      result: {
        data: null
      },
      more: true
    })

    subscription.received({
      result: {
        data: "data 1"
      },
      more: true
    })

    subscription.unsubscribe()

    expect(log).toEqual([
      [
        "perform", {
          actionName: "execute",
          options: {
            query: "subscription {\n  foo {\n    bar\n  }\n}\n",
            variables: { a: 1 },
            operationId: "operationId",
            operationName: "operationName"
          }
        }
      ],
      ["received", { data: "data 1" }],
      ["unsubscribe"]
    ])
  })
})
