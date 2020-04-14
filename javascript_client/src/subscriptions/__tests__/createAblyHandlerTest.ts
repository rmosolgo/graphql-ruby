import { createAblyHandler } from "../createAblyHandler"
import { Realtime } from "ably"

const dummyOperation = { text: "", name: "" }

const channelTemplate = {
  presence: {
    enter() {},
    enterClient() {},
    leave() {}
  },
  subscribe: () => {},
  unsubscribe: () => {}
}

const createDummyConsumer = (channel: any = channelTemplate): Realtime =>
  (({
    auth: { clientId: "foo" },
    channels: {
      get: () => channel
    }
  } as unknown) as Realtime)

const nextTick = () => new Promise(resolve => setTimeout(resolve, 0))

describe("createAblyHandler", () => {
  it("returns a function producing a disposable subscription", async () => {
    var wasDisposed = false

    const producer = createAblyHandler({
      fetchOperation: () =>
        new Promise(resolve =>
          resolve({ headers: new Map(), body: { data: { foo: "bar" } } })
        ),
      ably: createDummyConsumer({
        ...channelTemplate,
        unsubscribe: () => {
          wasDisposed = true
        }
      })
    })

    const subscription = producer(
      dummyOperation,
      {},
      {},
      { onError: () => {}, onNext: () => {}, onCompleted: () => {} }
    )

    await nextTick()
    subscription.dispose()
    expect(wasDisposed).toEqual(true)
  })

  it("dispatches the immediate response in case of success", async () => {
    let errorInvokedWith = undefined
    let nextInvokedWith = undefined

    const producer = createAblyHandler({
      fetchOperation: () =>
        new Promise(resolve =>
          resolve({ headers: new Map(), body: { data: { foo: "bar" } } })
        ),
      ably: createDummyConsumer()
    })

    producer(
      dummyOperation,
      {},
      {},
      {
        onError: (errors: any) => {
          errorInvokedWith = errors
        },
        onNext: (response: any) => {
          nextInvokedWith = response
        },
        onCompleted: () => {}
      }
    )

    await nextTick()
    expect(errorInvokedWith).toBeUndefined()
    expect(nextInvokedWith).toEqual({ data: { foo: "bar" } })
  })

  it("dispatches the immediate response in case of error", async () => {
    let errorInvokedWith = undefined
    let nextInvokedWith = undefined

    const dummyErrors = [{ message: "baz" }]

    const producer = createAblyHandler({
      fetchOperation: () =>
        new Promise(resolve =>
          resolve({
            headers: new Map(),
            body: { errors: dummyErrors }
          })
        ),
      ably: createDummyConsumer()
    })

    producer(
      dummyOperation,
      {},
      {},
      {
        onError: (errors: any) => {
          errorInvokedWith = errors
        },
        onNext: () => {},
        onCompleted: () => {}
      }
    )

    await nextTick()
    expect(errorInvokedWith).toEqual(dummyErrors)
    expect(nextInvokedWith).toBeUndefined()
  })

  it("doesn't dispatch anything for an empty response", async () => {
    let errorInvokedWith = undefined
    let nextInvokedWith = undefined

    const producer = createAblyHandler({
      fetchOperation: () =>
        new Promise(resolve =>
          resolve({
            headers: new Map(),
            body: {}
          })
        ),
      ably: createDummyConsumer()
    })

    producer(
      dummyOperation,
      {},
      {},
      {
        onError: (errors: any) => {
          errorInvokedWith = errors
        },
        onNext: (response: any) => {
          nextInvokedWith = response
        },
        onCompleted: () => {}
      }
    )

    await nextTick()
    expect(errorInvokedWith).toBeUndefined()
    expect(nextInvokedWith).toBeUndefined()
  })

  it("dispatches caught errors", async () => {
    let errorInvokedWith = undefined
    let nextInvokedWith = undefined

    const error = new Error("blam")

    const producer = createAblyHandler({
      fetchOperation: () => new Promise((_resolve, reject) => reject(error)),
      ably: createDummyConsumer()
    })

    producer(
      dummyOperation,
      {},
      {},
      {
        onError: (errors: any) => {
          errorInvokedWith = errors
        },
        onNext: (response: any) => {
          nextInvokedWith = response
        },
        onCompleted: () => {}
      }
    )

    await nextTick()
    expect(errorInvokedWith).toBe(error)
    expect(nextInvokedWith).toBeUndefined()
  })
})
