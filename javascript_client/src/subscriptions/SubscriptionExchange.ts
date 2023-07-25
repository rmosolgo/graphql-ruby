import Pusher from "pusher-js"
import Urql from "urql"

type ForwardCallback = (...args: any[]) => void

const SubscriptionExchange = {
  create(options: { pusher: Pusher }) {
    const pusher = options.pusher
    return function(operation: Urql.Operation) {
      // urql will call `.subscribed` on the returned object:
      // https://github.com/FormidableLabs/urql/blob/f89cfd06d9f14ae9cb3be10b21bd5cbd12ca275c/packages/core/src/exchanges/subscription.ts#L68-L73
      // https://github.com/FormidableLabs/urql/blob/f89cfd06d9f14ae9cb3be10b21bd5cbd12ca275c/packages/core/src/exchanges/subscription.ts#L82-L97
      return {
        subscribe: ({next, error, complete}: { next: ForwardCallback, error: ForwardCallback, complete: ForwardCallback}) => {
          // Somehow forward the operation to be POSTed to the server,
          // I don't see an option for passing this on to the `fetchExchange`
          const fetchBody = JSON.stringify({
            query: operation.query,
            variables: operation.variables,
          })
          var pusherChannelName: string
          const subscriptionId = "" + operation.key
          var fetchOptions = operation.context.fetchOptions
          if (typeof fetchOptions === "function") {
            fetchOptions = fetchOptions()
          } else if (fetchOptions == null) {
            fetchOptions = {}
          }

          const headers = {
            ...(fetchOptions.headers),
            ...{
              'Content-Type': 'application/json',
              'X-Subscription-ID': subscriptionId
            }
          }

          const defaultFetchOptions = { method: "POST" }
          const mergedFetchOptions = {
            ...defaultFetchOptions,
            ...fetchOptions,
            body: fetchBody,
            headers: headers,
          }
          const fetchFn = operation.context.fetch || fetch
          fetchFn(operation.context.url, mergedFetchOptions)
            .then((fetchResult) => {
              // Get the server-provided subscription ID
              pusherChannelName = fetchResult.headers.get("X-Subscription-ID") as string
              // Set up a subscription to Pusher, forwarding updates to
              // the `next` function provided by urql
              const pusherChannel = pusher.subscribe(pusherChannelName)
              pusherChannel.bind("update", (payload: {result: object, more: boolean}) => {
                // Here's an update to this subscription,
                // pass it on:
                if (payload.result) {
                  next(payload.result)
                }
                // If the server signals that this is the end,
                // then unsubscribe the client:
                if (!payload.more) {
                  complete()
                }
              })
              // Continue processing the initial result for the subscription
              return fetchResult.json()
            })
            .then((jsonResult) => {
              // forward the initial result to urql
              next(jsonResult)
            })
            .catch(error)

          // urql will call `.unsubscribe()` if it's returned here:
          // https://github.com/FormidableLabs/urql/blob/f89cfd06d9f14ae9cb3be10b21bd5cbd12ca275c/packages/core/src/exchanges/subscription.ts#L102
          return {
            unsubscribe: () => {
              // When requested by urql, disconnect from this channel
              pusherChannelName && pusher.unsubscribe(pusherChannelName)
            }
          }
        }
      }
    }
  }
}


export default SubscriptionExchange
