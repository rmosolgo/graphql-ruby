import { Consumer, Subscription } from "@rails/actioncable";
import Urql from "urql"

type ForwardCallback = (...args: any[]) => void

const createUrqlActionCableSubscription = {
  create(options: { consumer: Consumer }) {
    const consumer = options.consumer
    let subscription: Subscription | null = null;
    return function(operation: Urql.Operation) {
      // urql will call `.subscribed` on the returned object:
      // https://github.com/FormidableLabs/urql/blob/f89cfd06d9f14ae9cb3be10b21bd5cbd12ca275c/packages/core/src/exchanges/subscription.ts#L68-L73
      // https://github.com/FormidableLabs/urql/blob/f89cfd06d9f14ae9cb3be10b21bd5cbd12ca275c/packages/core/src/exchanges/subscription.ts#L82-L97
      return {
        subscribe: ({next, error, complete}: { next: ForwardCallback, error: ForwardCallback, complete: ForwardCallback}) => {
          subscription = consumer.subscriptions.create("GraphqlChannel", {
            connected() {
                this.perform("execute", { query: operation.query, variables: operation.variables });
            },
            disconnected() {
                console.log("Subscription disconnected");
            },
            received(data: any) {
                if (data?.result?.errors) {
                  error(data.errors);
                }
                if (data?.result?.data) {
                  next(data.result)
                }
                if (!data.more) {
                  complete()
                }
            }
          })
          // urql will call `.unsubscribe()` if it's returned here:
          // https://github.com/FormidableLabs/urql/blob/f89cfd06d9f14ae9cb3be10b21bd5cbd12ca275c/packages/core/src/exchanges/subscription.ts#L102
          return {
            unsubscribe: () => {
              if (subscription) {
                subscription.unsubscribe();
                subscription = null;
              }
            }
          }
        }
      }
    }
  }
}

export default createUrqlActionCableSubscription
