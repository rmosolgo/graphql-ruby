import createRelaySubscriptionHandler from "../createRelaySubscriptionHandler"
import { createLegacyRelaySubscriptionHandler } from "../createRelaySubscriptionHandler"
import { Cable } from "actioncable"
import { Network} from 'relay-runtime'

describe("createRelaySubscriptionHandler", () => {
  it("returns a function producing a observable subscription", () => {
    var dummyActionCableConsumer = {
      subscriptions: {
        create: () => ({ unsubscribe: () => ( true) })
      },
    }

    var options = {
      cable: (dummyActionCableConsumer as unknown) as Cable
    }

    var handler = createRelaySubscriptionHandler(options)
    var fetchQuery: any
    // basically, make sure this doesn't blow up during type-checking or runtime
    expect(Network.create(fetchQuery, handler)).toBeTruthy()
  })
})

describe("createLegacyRelaySubscriptionHandler", () => {
  it("still works", () => {
    var dummyActionCableConsumer = {
      subscriptions: {
        create: () => ({ unsubscribe: () => ( true) })
      },
    }

    var options = {
      cable: (dummyActionCableConsumer as unknown) as Cable
    }

    expect(createLegacyRelaySubscriptionHandler(options)).toBeInstanceOf(Function)
  })
})
