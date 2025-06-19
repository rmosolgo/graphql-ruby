// An Apollo Link for using graphql-pro's Ably subscriptions
//
// @example Adding subscriptions to a HttpLink
//   // Load Ably and create a client
//   var Ably = require('ably')
//   // Be sure to create an API key with "Subscribe" and "Presence" permissions only,
//   // and use that limited API key here:
//   var ablyClient = new Ably.Realtime({ key: "yourapp.key:secret" })
//
//   // Build a combined link, initialize the client:
//   const ablyLink = new AblyLink({ably: ablyClient})
//   const link = ApolloLink.from([authLink, ablyLink, httpLink])
//   const client = new ApolloClient(link: link, ...)
//
// @example Building a subscription, then subscribing to it
//  subscription = client.subscribe({
//    variables: { room: roomName},
//    query: gql`
//      subscription MessageAdded($room: String!) {
//        messageWasAdded(room: $room) {
//          room {
//            messages {
//              id
//              body
//              author {
//                screenname
//              }
//            }
//          }
//        }
//      }
//       `
//   })
//
//   subscription.subscribe({ next: ({data, errors}) => {
//     // Do something with `data` and/or `errors`
//   }})
//
import {
  ApolloLink,
  Observable,
  FetchResult,
  NextLink,
  Operation,
  Observer
} from "@apollo/client/core"
import { Realtime, Types } from "ably"

type RequestResult = FetchResult<
  { [key: string]: any },
  Record<string, any>,
  Record<string, any>
>

type Subscription = {
  closed: boolean
  unsubscribe(): void
}

class AblyLink extends ApolloLink {
  ably: Realtime

  constructor(options: { ably: Realtime }) {
    super()
    // Retain a handle to the Ably client
    this.ably = options.ably
  }

  request(operation: Operation, forward: NextLink): Observable<RequestResult> {
    const subscribeObservable = new Observable<RequestResult>(_observer => {})

    // Capture the super method
    const prevSubscribe = subscribeObservable.subscribe.bind(
      subscribeObservable
    )

    // Override subscribe to return an `unsubscribe` object, see
    // https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L182-L212
    subscribeObservable.subscribe = (
      observerOrNext:
        | Observer<RequestResult>
        | ((value: RequestResult) => void),
      onError?: (error: any) => void,
      onComplete?: () => void
    ): Subscription => {
      // Call super
      if (typeof observerOrNext == "function") {
        prevSubscribe(observerOrNext, onError, onComplete)
      } else {
        prevSubscribe(observerOrNext)
      }

      const observer = getObserver(observerOrNext, onError, onComplete)
      let ablyChannel: Types.RealtimeChannelCallbacks | null = null
      let subscriptionChannelId: string | null = null

      // Check the result of the operation
      const resultObservable = forward(operation)
      // When the operation is done, try to get the subscription ID from the server
      const resultSubscription = resultObservable.subscribe({
        next: (data: any) => {
          // If the operation has the subscription header, it's a subscription
          const subscriptionChannelConfig = this._getSubscriptionChannel(
            operation
          )
          if (subscriptionChannelConfig.channel) {
            subscriptionChannelId = subscriptionChannelConfig.channel
            // This will keep pushing to `.next`
            ablyChannel = this._createSubscription(
              subscriptionChannelConfig,
              observer
            )
          } else {
            // This isn't a subscription,
            // So pass the data along and close the observer.
            if (data) {
              observer.next(data)
            }
            observer.complete()
          }
        },
        error: observer.error
        // complete: observer.complete Don't pass this because Apollo unsubscribes if you do
      })

      // Return an object that will unsubscribe _if_ the query was a subscription.
      return {
        closed: false,
        unsubscribe: () => {
          if (ablyChannel && subscriptionChannelId) {
            const ablyClientId = this.ably.auth.clientId
            if (ablyClientId) {
              ablyChannel.presence.leave()
            } else {
              ablyChannel.presence.leaveClient("graphql-subscriber")
            }
            ablyChannel.unsubscribe()
            resultSubscription.unsubscribe()
          }
        }
      }
    }

    return subscribeObservable
  }

  _getSubscriptionChannel(operation: Operation) {
    const response = operation.getContext().response
    // Check to see if the response has the header
    const subscriptionChannel = response.headers.get("X-Subscription-ID")
    // The server returns this header when encryption is enabled.
    const cipherKey = response.headers.get("X-Subscription-Key")
    return { channel: subscriptionChannel, key: cipherKey }
  }

  _createSubscription(
    subscriptionChannelConfig: { channel: string; key: string },
    observer: { next: Function; complete: Function }
  ) {
    const subscriptionChannel = subscriptionChannelConfig["channel"]
    const subscriptionKey = subscriptionChannelConfig["key"]
    const ablyOptions = subscriptionKey
      ? { cipher: { key: subscriptionKey } }
      : {}
    const ablyChannel = this.ably.channels.get(subscriptionChannel, ablyOptions)
    const ablyClientId = this.ably.auth.clientId
    // Register presence, so that we can detect empty channels and clean them up server-side
    if (ablyClientId) {
      ablyChannel.presence.enter()
    } else {
      ablyChannel.presence.enterClient("graphql-subscriber", "subscribed")
    }
    // Subscribe for more update
    ablyChannel.subscribe("update", function(message) {
      var payload = message.data
      const result = payload.result
      if (result) {
        // Send the new response to listeners
        observer.next(result)
      }
      if (!payload.more) {
        // This is the end, the server says to unsubscribe
        if (ablyClientId) {
          ablyChannel.presence.leave()
        } else {
          ablyChannel.presence.leaveClient("graphql-subscriber")
        }
        ablyChannel.unsubscribe()
        observer.complete()
      }
    })
    return ablyChannel
  }
}

// Turn `subscribe` arguments into an observer-like thing, see getObserver
// https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L347-L361
function getObserver<T>(
  observerOrNext: Function | Observer<T>,
  onError?: (e: Error) => void,
  onComplete?: () => void
) {
  if (typeof observerOrNext === "function") {
    // Duck-type an observer
    return {
      next: (v: T) => observerOrNext(v),
      error: (e: Error) => onError && onError(e),
      complete: () => onComplete && onComplete()
    }
  } else {
    // Make an object that calls to the given object, with safety checks
    return {
      next: (v: T) => observerOrNext.next && observerOrNext.next(v),
      error: (e: Error) => observerOrNext.error && observerOrNext.error(e),
      complete: () => observerOrNext.complete && observerOrNext.complete()
    }
  }
}

export default AblyLink
