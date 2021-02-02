// An Apollo Link for using graphql-pro's Pusher subscriptions
//
// @example Adding subscriptions to a HttpLink
//   // Load Pusher and create a client
//   import Pusher from "pusher-js"
//   var pusherClient = new Pusher("your-app-key", { cluster: "us2" })
//
//   // Build a combined link, initialize the client:
//   const pusherLink = new PusherLink({pusher: pusherClient})
//   const link = ApolloLink.from([authLink, pusherLink, httpLink])
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
import { ApolloLink, Observable, Operation, NextLink, FetchResult } from "apollo-link"
import Pusher from "pusher-js"


type RequestResult = Observable<FetchResult<{ [key: string]: any; }, Record<string, any>, Record<string, any>>>

class PusherLink extends ApolloLink {
  pusher: Pusher
  decompress: (result: string) => any

  constructor(options: { pusher: Pusher, decompress?: (result: string) => any}) {
    super()
    // Retain a handle to the Pusher client
    this.pusher = options.pusher
    if (options.decompress) {
      this.decompress = options.decompress
    } else {
      this.decompress = function(_result: string) {
        throw new Error("Received compressed_result but PusherLink wasn't configured with `decompress: (result: string) => any`. Add this configuration.")
      }
    }
  }

  request(operation: Operation, forward: NextLink): RequestResult {
    const subscribeObservable = new Observable((_observer) => {  }) as RequestResult
    // Capture the super method
    const prevSubscribe = subscribeObservable.subscribe.bind(subscribeObservable)

    // Override subscribe to return an `unsubscribe` object, see
    // https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L182-L212
    subscribeObservable.subscribe = (observerOrNext: any, onError: (error: any) => void, onComplete: () => void) => {
      // Call super
      prevSubscribe(observerOrNext, onError, onComplete)
      const observer = getObserver(observerOrNext, onError, onComplete)
      var subscriptionChannel: string
      // Check the result of the operation
      const resultObservable = forward(operation)
      // When the operation is done, try to get the subscription ID from the server
      resultObservable.subscribe({ next: (data) => {
        // If the operation has the subscription header, it's a subscription
        const response = operation.getContext().response
        // Check to see if the response has the header
        subscriptionChannel = response.headers.get("X-Subscription-ID")
        if (subscriptionChannel) {
          // Set up the pusher subscription for updates from the server
          const pusherChannel = this.pusher.subscribe(subscriptionChannel)
          // Subscribe for more update
          pusherChannel.bind("update", (payload: any) => {
            this._onUpdate(subscriptionChannel, observer, payload)
          })
        } else {
          // This isn't a subscription,
          // So pass the data along and close the observer.
          observer.next(data)
          observer.complete()
        }
      }})
      // Return an object that will unsubscribe _if_ the query was a subscription.
      return {
        closed: false,
        unsubscribe: () => {
          subscriptionChannel && this.pusher.unsubscribe(subscriptionChannel)
        }
      }
    }

    return subscribeObservable
  }

  _onUpdate(subscriptionChannel: string, observer: { next: Function, complete: Function }, payload: {more: boolean, compressed_result?: string, result?: object}): void {
    if (!payload.more) {
      // This is the end, the server says to unsubscribe
      this.pusher.unsubscribe(subscriptionChannel)
      observer.complete()
    }
    let result: any
    if (payload.compressed_result) {
      result = this.decompress(payload.compressed_result)
    } else {
      result = payload.result
    }
    if (result) {
      // Send the new response to listeners
      observer.next(result)
    }
  }
}



// Turn `subscribe` arguments into an observer-like thing, see getObserver
// https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L329-L343
function getObserver(observerOrNext: Function | {next: Function, error: Function, complete: Function}, onError: Function, onComplete: Function) {
  if (typeof observerOrNext === 'function') {
    // Duck-type an observer
    return {
      next: (v: object) => observerOrNext(v),
      error: (e: object) => onError && onError(e),
      complete: () => onComplete && onComplete(),
    }
  } else {
    // Make an object that calls to the given object, with safety checks
    return {
      next: (v: object) => observerOrNext.next && observerOrNext.next(v),
      error: (e: object) => observerOrNext.error && observerOrNext.error(e),
      complete: () => observerOrNext.complete && observerOrNext.complete(),
    }
  }
}

export default PusherLink
export { getObserver }
