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
import { Observable } from "@apollo/client"
import { ApolloLink } from "@apollo/client/link"
import { Realtime, Types } from "ably"

type RequestResult = ApolloLink.Result<Record<string, any>, Record<string, any>>

class AblyLink extends ApolloLink {
  ably: Realtime

  constructor(options: { ably: Realtime }) {
    super()
    // Retain a handle to the Ably client
    this.ably = options.ably
  }

  request(operation: ApolloLink.Operation, forward: ApolloLink.ForwardFunction): Observable<RequestResult> {
    return new Observable((observer) => {
      let ablyChannel: Types.RealtimeChannelCallbacks | null = null
      let subscriptionChannelId: string | null = null
      // Check the result of the operation
      const resultObserver = forward(operation)
      const resultSubscription = resultObserver.subscribe({
        next: (data: any) => {
          // If the operation has the subscription header, it's a subscription
          const subscriptionChannelConfig = this._getSubscriptionChannel(operation)
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
    });
  }

  _getSubscriptionChannel(operation: ApolloLink.Operation) {
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

export default AblyLink
