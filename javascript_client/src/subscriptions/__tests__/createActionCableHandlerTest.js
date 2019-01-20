import createActionCableHandler from "../createActionCableHandler";

describe("createActionCableHandler", () => {
  it("returns a function producing a disposable subscription", () => {
    var wasDisposed = false

    var subscription = {
      unsubscribe: () => (wasDisposed = true)
    }
    var dummyActionCableConsumer = {
      subscriptions: {
        create: () => subscription
      }
    }

    var producer = createActionCableHandler(dummyActionCableConsumer)
    producer().dispose()

    expect(wasDisposed).toEqual(true)
  })
})
