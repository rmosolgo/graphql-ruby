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
import { Observable } from "@apollo/client"
import { ApolloLink } from "@apollo/client/link"
import Pusher from "pusher-js"

type RequestResult = ApolloLink.Result<Record<string, any>, Record<string, any>>

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

  request(operation: ApolloLink.Operation, forward: ApolloLink.ForwardFunction): Observable<RequestResult> {
    return new Observable((observer) => {
      var subscriptionChannel: string
      // Check the result of the operation
      const resultObservable = forward(operation)
      // When the operation is done, try to get the subscription ID from the server
      resultObservable.subscribe({
        next: (data: any) => {
          // If the operation has the subscription header, it's a subscription
          const response = operation.getContext().response
          // Check to see if the response has the header
          subscriptionChannel = response.headers.get("X-Subscription-ID")
          if (subscriptionChannel) {
            // Set up the pusher subscription for updates from the server
            const pusherChannel = this.pusher.subscribe(subscriptionChannel)
            // Pass along the initial payload:
            if (data.data && Object.keys(data.data).length > 0) {
              observer.next(data)
            }
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
        },
        error: observer.error,
        // complete: observer.complete Don't pass this because Apollo unsubscribes if you do
      })

      // Return an object that will unsubscribe _if_ the query was a subscription.
      return {
        closed: false,
        unsubscribe: () => {
          subscriptionChannel && this.pusher.unsubscribe(subscriptionChannel)
        }
      }
    })

  }

  _onUpdate(subscriptionChannel: string, observer: { next: Function, complete: Function }, payload: {more: boolean, compressed_result?: string, result?: object}): void {
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
    if (!payload.more) {
      // This is the end, the server says to unsubscribe
      this.pusher.unsubscribe(subscriptionChannel)
      observer.complete()
    }
  }
}


export default PusherLink
