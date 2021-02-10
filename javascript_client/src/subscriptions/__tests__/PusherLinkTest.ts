import PusherLink from "../PusherLink"
import { parse } from "graphql"
import { Pusher } from "pusher-js"
import { Operation } from "@apollo/client"

type MockChannel = {
  bind: (action: string, handler: Function) => void,
}

describe("ActionCableLink", () => {
  var channelName = "abcd-efgh"
  var log: any[]
  var pusher: any
  var options: any
  var link: any
  var query: any
  var operation: Operation

  beforeEach(() => {
    log = []
    pusher = {
      _channels: {},
      trigger: function(channel: string, event: string, data: any) {
        var handlers = this._channels[channel]
        if (handlers) {
          handlers.forEach(function(handler: [string, Function]) {
            if (handler[0] == event) {
              handler[1](data)
            }
          })
        }
      },
      subscribe: function(channel: string): MockChannel {
        log.push(["subscribe", channel])
        var handlers = this._channels[channel]
        if (!handlers) {
          handlers = this._channels[channel] = []
        }

        return {
          bind: (action: string, handler: Function): void => {
            handlers.push([action, handler])
          }
        }
      },
      unsubscribe: (channel: string): void => {
        log.push(["unsubscribe", channel])
      },
    }

    options = {
      pusher: (pusher as unknown) as Pusher
    }
    link = new PusherLink(options)

    query = parse("subscription { foo { bar } }")

    operation = ({
      query: query,
      variables: { a: 1 },
      operationId: "operationId",
      operationName: "operationName",
      getContext: () => {
        return {
          response: {
            headers: {
              get: (headerName: string) => {
                if (headerName == "X-Subscription-ID") {
                  return channelName
                } else {
                  throw "Unsupported header name: " + headerName
                }
              }
            }
          }
        }
      }
    } as unknown) as Operation
  })

  it("delegates to pusher", () => {
    var requestFinished: Function = () => {}

    var observable = link.request(operation, function(_operation: Operation): any {
      return {
        subscribe: (options: { next: Function }): void => {
          requestFinished = options.next
        }
      }
    })

    // unpack the underlying subscription
    observable.subscribe(function(result: any) {
      log.push(["received", result])
    })

    // Pretend the HTTP link finished
    requestFinished({})

    pusher.trigger(channelName, "update", {
      result: {
        data: "data 1"
      },
      more: true
    })

    pusher.trigger(channelName, "update", {
      result: {
        data: "data 2"
      },
      more: false
    })

    expect(log).toEqual([
      ["subscribe", "abcd-efgh"],
      ["received", { data: "data 1" }],
      ["received", { data: "data 2" }],
      ["unsubscribe", "abcd-efgh"]
    ])
  })

  it("delegates a manual unsubscribe to the cable", () => {
    var requestFinished: Function = () => {}

    var observable = link.request(operation, function(_operation: Operation): any {
      return {
        subscribe: (options: { next: Function }): void => {
          requestFinished = options.next
        }
      }
    })

    // unpack the underlying subscription
    var subscription = observable.subscribe(function(result: any) {
      log.push(["received", result])
    })

    // Pretend the HTTP link finished
    requestFinished({})

    pusher.trigger(channelName, "update", {
      result: {
        data: "data 1"
      },
      more: true
    })

    subscription.unsubscribe()

    expect(log).toEqual([
      ["subscribe", "abcd-efgh"],
      ["received", { data: "data 1" }],
      ["unsubscribe", "abcd-efgh"]
    ])
  })
})
