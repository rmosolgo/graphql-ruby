import { createActionCableHandler } from "../createActionCableHandler"
import type { Consumer } from "@rails/actioncable"

describe("createActionCableHandler", () => {
  it("returns a function producing a disposable subscription", () => {
    var wasDisposed = false

    var subscription = {
      unsubscribe: () => (wasDisposed = true)
    }
    var dummyActionCableConsumer = {
      subscriptions: {
        create: () => subscription
      },
    }

    var options = {
      cable: (dummyActionCableConsumer as unknown) as Consumer
    }
    var producer = createActionCableHandler(options)
    producer({text: "", name: ""}, {}, {}, { onError: () => {}, onNext: () => {}, onCompleted: () => {} }).dispose()

    expect(wasDisposed).toEqual(true)
  })

  it("uses a provided clientName and operation.id", () => {
    var handlers: any
    var log: [string, any][]= []

    var dummyActionCableConsumer = {
      subscriptions: {
        create: (_conn: any, newHandlers: any) => {
          handlers = newHandlers
          return {
            perform: (evt: string, data: any) => {
              log.push([evt, data])
            }
          }
        }
      }
    }

    var options = {
      cable: (dummyActionCableConsumer as unknown) as Consumer,
      clientName: "client-1",
    }

    var producer = createActionCableHandler(options);

    producer(
      {text: "", name: "", id: "abcdef"},
      {},
      {},
      { onError: () => {}, onNext: (result: any) => { log.push(["onNext", result])}, onCompleted: () => { log.push(["onCompleted", null])} }
    )

    handlers.connected() // trigger the GraphQL send
    handlers.received({ result: { data: { a: "1" } }, more: false })

    expect(log).toEqual([
      ["execute", { operationId: "client-1/abcdef", operationName: "", query: "", variables: {} }],
      ["onNext", { data: { a: "1" } }],
      ["onCompleted", null],
    ])
  })
})
