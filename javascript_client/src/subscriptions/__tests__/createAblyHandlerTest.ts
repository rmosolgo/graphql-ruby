import { createAblyHandler } from "../createAblyHandler"
import { Realtime, Types } from "ably"

const dummyOperation = { text: "", name: "" }

const channelTemplate = {
  presence: {
    enter() {},
    enterClient() {},
    leave(callback?: (err?: Types.ErrorInfo) => void) {
      if (callback) callback()
    }
  },
  subscribe: () => {},
  unsubscribe: () => {},
  on: () => {},
  detach: (callback?: (err?: Types.ErrorInfo) => void) => {
    if (callback) callback()
  }
}

const createDummyConsumer = (
  channel: any = channelTemplate,
  release = (_channelName: string) => {}
): Realtime =>
  (({
    auth: { clientId: "foo" },
    channels: {
      get: () => channel,
      release
    }
  } as unknown) as Realtime)

const nextTick = () => new Promise(resolve => setTimeout(resolve, 0))

describe("createAblyHandler", () => {
  it("returns a function producing a disposable subscription", async () => {
    const subscriptionId = "dummy-subscription"
    var wasUnsubscribed = false
    var wasDetached = false
    var releasedChannelName

    const producer = createAblyHandler({
      fetchOperation: () =>
        new Promise(resolve =>
          resolve({
            headers: new Map([["X-Subscription-ID", subscriptionId]]),
            body: { data: { foo: "bar" } }
          })
        ),
      ably: createDummyConsumer(
        {
          ...channelTemplate,
          unsubscribe: () => {
            wasUnsubscribed = true
          },
          detach: (callback?: (err?: Types.ErrorInfo) => void) => {
            if (callback) callback()
            wasDetached = true
          },
          name: subscriptionId
        },
        (channelName: string) => {
          releasedChannelName = channelName
        }
      )
    })

    const subscription = producer(
      dummyOperation,
      {},
      {},
      { onError: () => {}, onNext: () => {}, onCompleted: () => {} }
    )

    await nextTick()
    await subscription.dispose()
    expect(wasUnsubscribed).toEqual(true)
    expect(wasDetached).toEqual(true)
    expect(releasedChannelName).toEqual(subscriptionId)
  })

  it("dispatches the immediate response in case of success", async () => {
    let errorInvokedWith = undefined
    let nextInvokedWith = undefined

    const producer = createAblyHandler({
      fetchOperation: () =>
        new Promise(resolve =>
          resolve({
            headers: new Map([["X-Subscription-ID", "foo"]]),
            body: { data: { foo: "bar" } }
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
            headers: new Map([["X-Subscription-ID", "foo"]]),
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
            headers: new Map([["X-Subscription-ID", "foo"]]),
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

  it("detaches the channel when the subscription is disposed during initial response", async () => {
    let detached = false

    const ably = createDummyConsumer({
      ...channelTemplate,
      detach() {
        detached = true
      }
    })
    const producer = createAblyHandler({
      fetchOperation: () =>
        new Promise(resolve =>
          resolve({
            headers: new Map([["X-Subscription-ID", "foo"]]),
            body: { errors: {} }
          })
        ),
      ably
    })

    const { dispose } = producer(
      dummyOperation,
      {},
      {},
      {
        onError: async () => {
          dispose()
        },
        onNext: async () => {},
        onCompleted: () => {}
      }
    )

    await nextTick()
    expect(detached).toBe(true)
  })

  describe("integration with Ably", () => {
    const key = process.env.ABLY_KEY
    const testWithAblyKey = key ? test : test.skip

    test("onError is called when using invalid key", async () => {
      const ably = new Realtime({
        key: "integration-test:invalid",
        log: { level: 0 }
      })
      await new Promise(resolve => {
        const fetchOperation = async () => ({
          headers: new Map([["X-Subscription-ID", "foo"]])
        })

        const ablyHandler = createAblyHandler({ ably, fetchOperation })
        const operation = {}
        const variables = {}
        const cacheConfig = {}
        const onError = (error: any) => {
          expect(error.message).toMatch(/Invalid key in request/)
          resolve()
        }
        const onNext = () => console.log("onNext")
        const onCompleted = () => console.log("onCompleted")
        const observer = {
          onError,
          onNext,
          onCompleted
        }
        ablyHandler(operation, variables, cacheConfig, observer)
      })
      ably.close()
    })

    // For executing this test you need to provide a valid Ably API key in
    // environment variable ABLY_KEY
    testWithAblyKey(
      "onError is called for too many subscriptions",
      async () => {
        const ably = new Realtime({ key, log: { level: 0 } })
        await new Promise(resolve => {
          let subscriptionCounter = 0
          const fetchOperation = async () => {
            subscriptionCounter += 1
            return {
              headers: new Map([
                ["X-Subscription-ID", `foo-${subscriptionCounter}`]
              ])
            }
          }
          const ablyHandler = createAblyHandler({ ably, fetchOperation })
          const operation = {}
          const variables = {}
          const cacheConfig = {}
          const onError = (error: any) => {
            expect(error.message).toMatch(/Maximum number of channels/)
            resolve()
          }
          const onNext = () => console.log("onNext")
          const onCompleted = () => console.log("onCompleted")
          const observer = {
            onError,
            onNext,
            onCompleted
          }
          for (let i = 0; i < 201; ++i) {
            ablyHandler(operation, variables, cacheConfig, observer)
          }
        })

        ably.close()
      }
    )

    // For executing this test you need to provide a valid Ably API key in
    // environment variable ABLY_KEY
    testWithAblyKey("can make more than 200 subscriptions", async () => {
      let caughtError = null
      const ably = new Realtime({ key, log: { level: 0 } })
      let subscriptionCounter = 0
      const fetchOperation = async () => {
        subscriptionCounter += 1
        return {
          headers: new Map([
            ["X-Subscription-ID", `foo-${subscriptionCounter}`]
          ])
        }
      }
      const ablyHandler = createAblyHandler({ ably, fetchOperation })
      const operation = {}
      const variables = {}
      const cacheConfig = {}
      const onError = (error: Error) => {
        caughtError = error
      }
      const onNext = () => {}
      const onCompleted = () => {}
      const observer = {
        onError,
        onNext,
        onCompleted
      }
      for (let i = 0; i < 201; ++i) {
        const { dispose } = ablyHandler(
          operation,
          variables,
          cacheConfig,
          observer
        )
        await new Promise(resolve => setTimeout(resolve, 0))

        dispose()
      }

      await new Promise(resolve => setTimeout(resolve, 500))

      ably.close()

      if (caughtError) throw caughtError
    })
  })
})
