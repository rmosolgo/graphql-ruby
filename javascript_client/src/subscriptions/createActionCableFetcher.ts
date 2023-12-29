
import { visit } from "graphql";
import type { Consumer, Subscription } from "@rails/actioncable"

type ActionCableFetcherOptions = {
  consumer: Consumer,
  url: string,
  fetch?: typeof fetch,
  fetchOptions?: any,
}

type SubscriptionIteratorPayload = {
  value: any,
  done: Boolean
}

export default function createActionCableFetcher(options: ActionCableFetcherOptions) {
  let currentChannel: Subscription | null = null
  const consumer = options.consumer

  const subscriptionFetcher = async function*(graphqlParams: any, fetcherOpts: any) {
    let isSubscription = false;
    let nextPromiseResolve: Function | null = null;

    fetcherOpts.documentAST && visit(fetcherOpts.documentAST, {
      OperationDefinition(node) {
        if (graphqlParams.operationName === node.name?.value && node.operation === 'subscription') {
          isSubscription = true;
        }
      },
    });

    if (isSubscription) {
      currentChannel?.unsubscribe()
      currentChannel = consumer.subscriptions.create("GraphqlChannel",
        {
          connected: function() {
            currentChannel?.perform("execute", {
              query: graphqlParams.query,
              operationName: graphqlParams.operationName,
              variables: graphqlParams.variables,
            })
          },

          received: function(data: any) {
            if (nextPromiseResolve) {
              nextPromiseResolve({ value: data.result, done: false })
            }
          }
        } as any
      )

      var iterator = {
        [Symbol.asyncIterator]() {
          return {
            next(): Promise<SubscriptionIteratorPayload> {
              return new Promise((resolve, _reject) => {
                nextPromiseResolve = resolve
              })
            },
            return(): Promise<SubscriptionIteratorPayload> {
              if (currentChannel) {
                currentChannel.unsubscribe()
                currentChannel = null
              }
              return Promise.resolve({ value: null, done: true })
            }
          }
        }
      }

      for await (const payload of iterator) {
        yield payload
      }
    } else {
      const fetchFn = options.fetch || window.fetch
      // Not a subscription fetcher, post to the given URL
      yield fetchFn("/graphql", {
        method: "POST",
        body: JSON.stringify({
          query: graphqlParams.query,
          operationName: graphqlParams.operationName,
          variables: graphqlParams.variables,
        }),
        headers: {
          'content-type': 'application/json',
        },
        ... options.fetchOptions
      }).then((r) => r.json())
      return
    }
  }

  return subscriptionFetcher
}
