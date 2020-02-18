import { createActionCableHandler } from "../createActionCableHandler"
import { Cable } from "actioncable"
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
      cable: (dummyActionCableConsumer as unknown) as Cable
    }
    var producer = createActionCableHandler(options)
    producer({text: "", name: ""}, {}, {}, { onError: () => {}, onNext: () => {}, onCompleted: () => {} }).dispose()

    expect(wasDisposed).toEqual(true)
  })
})
