// An Apollo Link for using graphql-pro's Pubnub subscriptions
//
import { ApolloLink, Observable, FetchResult, NextLink, Operation } from "apollo-link"
import Pubnub from "pubnub"

type RequestResult = Observable<FetchResult<{ [key: string]: any; }, Record<string, any>, Record<string, any>>>

class PubnubLink extends ApolloLink {
  pubnub: Pubnub
  handlersBySubscriptionId: { [key: string]: Function }

  constructor(options: { pubnub: Pubnub }) {
    super()
    this.pubnub = options.pubnub
    this.handlersBySubscriptionId = {}
    this.pubnub.addListener({
      message: (message) => {
        const subscriptionChannel = message.channel
        const handler = this.handlersBySubscriptionId[subscriptionChannel]
        if (handler) {
          // Send along { result: {...}, more: true|false }
          handler(message.message)
        }
      }
    })
  }

  request(operation: Operation, forward: NextLink): RequestResult {
    return new Observable((observer) => {
      // Check the result of the operation
      forward(operation).subscribe({ next: (data) => {
        // If the operation has the subscription header, it's a subscription
        const subscriptionChannel = this._getSubscriptionChannel(operation)
        if (subscriptionChannel) {
          // This will keep pushing to `.next`
          this._createSubscription(subscriptionChannel, observer)
        }
        else {
          // This isn't a subscription,
          // So pass the data along and close the observer.
          observer.next(data)
          observer.complete()
        }
      }})
    })
  }

  _getSubscriptionChannel(operation: Operation) {
    const response = operation.getContext().response
    // Check to see if the response has the header
    const subscriptionChannel = response.headers.get("X-Subscription-ID")
    return subscriptionChannel
  }

  _createSubscription(subscriptionChannel: string, observer: { next: Function, complete: Function}) {
    this.pubnub.subscribe({channels: [subscriptionChannel], withPresence: true})
    this.handlersBySubscriptionId[subscriptionChannel] = (payload: { more: Boolean, result: Object }) => {
      // Sent the subscription update along to Apollo
      if (payload.result) {
        observer.next(payload.result)
      }
      // The server unsubscribed; unsubscribe
      if (!payload.more) {
        this.pubnub.unsubscribe({ channels: [subscriptionChannel] })
        delete this.handlersBySubscriptionId[subscriptionChannel]
        observer.complete()
      }
    }
  }
}

export default PubnubLink
