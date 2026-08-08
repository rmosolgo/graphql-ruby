# urql Subscriptions

GraphQL-Ruby currently supports using `urql` with the [ActionCable](/subscriptions/action_cable_implementation) and [Pusher implementation](/subscriptions/pusher_implementation).

## Pusher

```js
import SubscriptionExchange from "graphql-ruby-client/subscriptions/SubscriptionExchange"
import Pusher from "pusher"
import { Client, defaultExchanges, subscriptionExchange } from 'urql'

const pusherClient = new Pusher("your-app-key", { cluster: "us2" })
const forwardToPusher = SubscriptionExchange.create({ pusher: pusherClient })

const client = new Client({
  url: '/graphql',
  exchanges: [
    ...defaultExchanges,
    subscriptionExchange({
      forwardSubscription: forwardToPusher
    }),
  ],
});
```

## ActionCable

```js
import { createConsumer } from "@rails/actioncable";
import SubscriptionExchange from "graphql-ruby-client/subscriptions/SubscriptionExchange"

const actionCable = createConsumer('ws://127.0.0.1:3000/cable');
const forwardToActionCable = SubscriptionExchange.create({ consumer: actionCable })

const client = new Client({
  url: '/graphql',
  exchanges: [
    ...defaultExchanges,
    subscriptionExchange({
      forwardSubscription: forwardToActionCable
    }),
  ],
});
```

Want to use `urql` with another subscription backend? Please [open an issue](https://github.com/rmosolgo/graphql-ruby/issues/new?title=Using+urql+with+...&body=).
