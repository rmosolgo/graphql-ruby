import ActionCableLink from "../ActionCableLink"
import { parse } from "graphql"
import { Cable } from "actioncable"
import { Operation } from "apollo-link"

describe("ActionCableLink", () => {
  it("delegates to the cable", () => {
    var log: any[] = []
    var subscription: any
    var cable = {
      subscriptions: {
        create: function(_channelName: string, options: {connected: Function, perform: Function, received: Function}) {
          subscription = Object.assign(options, {
            perform: function(actionName: string, options: object) {
              log.push(["perform", { actionName: actionName, options: options }])
            },
            unsubscribe: function() {
              log.push(["unsubscribe"])
            },
          })
          subscription.connected = subscription.connected.bind(subscription)
          subscription.connected()
        }
      }
    }

    var options = {
      cable: (cable as unknown) as Cable
    }
    var link = new ActionCableLink(options)

    var query = parse("subscription { foo { bar } }")

    var operation = ({
      query: query,
      variables: { a: 1 },
      operationId: "operationId",
      operationName: "operationName"
    } as unknown) as Operation

    var observable = link.request(operation, null as any)

    observable.subscribe(function(result: any) {
      log.push(["received", result])
    })

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
})
