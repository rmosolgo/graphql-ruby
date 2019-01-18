var ActionCableLink = require("../ActionCableLink")
var graphql = require("graphql")

describe("ActionCableLink", () => {
  it("delegates to the cable", () => {
    var log = []
    var subscription
    var cable = {
      subscriptions: {
        create: function(channelName, options) {
          subscription = Object.assign(options, {
            perform: function(actionName, options) {
              log.push(["perform", { actionName: actionName, options: options }])
            },
            unsubscribe: function() {
              log.push(["unsubscribe"])
            }
          })
          subscription.connected = subscription.connected.bind(subscription)
          subscription.perform = subscription.perform.bind(subscription)
          subscription.connected()
        }
      }
    }

    var link = new ActionCableLink({cable: cable})

    var query = graphql.parse("subscription { foo { bar } }")

    var observable = link.request({
      query: query,
      variables: { a: 1 },
      operationId: "operationId",
      operationName: "operationName"
    })

    observable.subscribe(function(result) {
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
