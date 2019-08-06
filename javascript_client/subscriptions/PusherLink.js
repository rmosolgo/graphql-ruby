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
var ApolloLink = require("apollo-link").ApolloLink
var Observable = require("apollo-link").Observable

class PusherLink extends ApolloLink {
  constructor(options) {
    super()
    // Retain a handle to the Pusher client
    this.pusher = options.pusher
  }

  request(operation, forward) {
    const subscribeObservable = new Observable((observer) => {  })

    // Capture the super method
    const prevSubscribe = subscribeObservable.subscribe.bind(subscribeObservable)

    // Override subscribe to return an `unsubscribe` object, see
    // https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L182-L212
    subscribeObservable.subscribe = (observerOrNext, onError, onComplete) => {
      // Call super
      prevSubscribe(observerOrNext, onError, onComplete)
      const observer = getObserver(observerOrNext, onError, onComplete)
      var subscriptionChannel = null
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
          pusherChannel.bind("update", function(payload) {
            if (!payload.more) {
              // This is the end, the server says to unsubscribe
              pusher.unsubscribe(subscriptionChannel)
              observer.complete()
            }
            const result = payload.result
            if (result) {
              // Send the new response to listeners
              observer.next(result)
            }
          })
        }
        else {
          // This isn't a subscription,
          // So pass the data along and close the observer.
          observer.next(data)
          observer.complete()
        }
      }})
      // Return an object that will unsubscribe _if_ the query was a subscription.
      return {
        unsubscribe: () => {
          subscriptionChannel && this.pusher.unsubscribe(subscriptionChannel)
        }
      }
    }

    return subscribeObservable
  }
}

// Turn `subscribe` arguments into an observer-like thing, see getObserver
// https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/client.ts#L329-L343
function getObserver(observerOrNext, onError, onComplete) {
  if (typeof observerOrNext === 'function') {
    // Duck-type an observer
    return {
      next: (v) => observerOrNext(v),
      error: (e) => onError && onError(e),
      complete: () => onComplete && onComplete(),
    }
  } else {
    // Make an object that calls to the given object, with safety checks
    return {
      next: (v) => observerOrNext.next && observerOrNext.next(v),
      error: (e) => observerOrNext.error && observerOrNext.error(e),
      complete: () => observerOrNext.complete && observerOrNext.complete(),
    }
  }
}

module.exports = PusherLink
