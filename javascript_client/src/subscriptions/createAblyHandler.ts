import { Realtime, Types } from "ably"
// TODO:
// - end-to-end test
// - extract update code, inject it as a function?

interface AblyHandlerOptions {
  ably: Realtime
  fetchOperation: Function
}

interface ApolloObserver {
  onError: Function
  onNext: Function
  onCompleted: Function
}

const anonymousClientId = "graphql-subscriber"

class AblyError {
  constructor(reason: Types.ErrorInfo) {
    const error = Error(reason.message)
    const attributes: (keyof Types.ErrorInfo)[] = ["code", "statusCode"]
    attributes.forEach(attr => {
      Object.defineProperty(error, attr, {
        get() {
          return reason[attr]
        }
      })
    })
    Error.captureStackTrace(error, AblyError)
    return error
  }
}

function createAblyHandler(options: AblyHandlerOptions) {
  var ably = options.ably
  var fetchOperation = options.fetchOperation

  const isAnonymousClient = () =>
    !ably.auth.clientId || ably.auth.clientId === "*"

  return function(
    operation: object,
    variables: object,
    cacheConfig: object,
    observer: ApolloObserver
  ) {
    var channelName: string
    var channel: Types.RealtimeChannelCallbacks

    // POST the subscription like a normal query
    fetchOperation(operation, variables, cacheConfig)
      .then(function(response: { headers: { get: Function }; body: any }) {
        const dispatchResult = (result: { errors: any; data: any }) => {
          if (result) {
            if (result.errors) {
              // What kind of error stuff belongs here?
              observer.onError(result.errors)
            } else if (result.data) {
              observer.onNext({ data: result.data })
            }
          }
        }
        dispatchResult(response.body)
        channelName = response.headers.get("X-Subscription-ID")
        channel = ably.channels.get(channelName)
        channel.on("failed", function(stateChange: Types.ChannelStateChange) {
          observer.onError(
            stateChange.reason
              ? new AblyError(stateChange.reason)
              : new Error("Ably channel changed to failed state")
          )
        })
        channel.on("suspended", function(
          stateChange: Types.ChannelStateChange
        ) {
          // Note: suspension can be a temporary condition and isn't necessarily
          // an error, however we handle the case where the channel gets
          // suspended before it is attached because that's the only way to
          // propagate error 90010 (see https://help.ably.io/error/90010)
          if (
            stateChange.previous === "attaching" &&
            stateChange.current === "suspended"
          ) {
            observer.onError(
              stateChange.reason
                ? new AblyError(stateChange.reason)
                : new Error("Ably channel suspended before being attached")
            )
          }
        })
        // Register presence, so that we can detect empty channels and clean them up server-side
        if (isAnonymousClient()) {
          channel.presence.enterClient(anonymousClientId, "subscribed")
        } else {
          channel.presence.enter("subscribed")
        }
        // When you get an update from ably, give it to Relay
        channel.subscribe("update", function(message) {
          // TODO Extract this code
          // When we get a response, send the update to `observer`
          var payload = message.data
          dispatchResult(payload.result)
          if (!payload.more) {
            // Subscription is finished
            observer.onCompleted()
          }
        })
      })
      .catch((error: any) => observer.onError(error))
    return {
      dispose: function() {
        if (channel) {
          if (isAnonymousClient()) {
            channel.presence.leaveClient(anonymousClientId)
          } else {
            channel.presence.leave()
          }
          channel.unsubscribe()
          channel.detach()
          ably.channels.release(channelName)
        }
      }
    }
  }
}

export { createAblyHandler, AblyHandlerOptions }
