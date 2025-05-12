import { Realtime } from "ably";
import type { ChannelStateChange, Message, RealtimeChannel } from "ably";

export interface AblyHandlerOptions {
  ably: Realtime;
  fetchOperation: (
    operation: object,
    variables: object,
    cacheConfig: object,
  ) => Promise<{ headers: Map<string, string>; body: unknown }>;
}

interface PayloadError {
  message: string;
  path: (string | number)[];
  locations: number[][];
  extensions?: object;
}

interface Observer {
  onError: (error: Error) => void;
  onNext: (value: unknown) => void;
  onCompleted: () => void;
}

class PayloadErrorsError extends Error {
  errors: PayloadError[];

  constructor(errors: PayloadError[]) {
    super(JSON.stringify(errors));
    this.errors = errors;
  }
}

const anonymousClientId = "graphql-subscriber";

// Current max. number of rewound messages in the initial response to
// subscribe. See
// https://github.com/ably/docs/blob/baa0a4666079abba3a3e19e82eb99ca8b8a735d0/content/realtime/channels/channel-parameters/rewind.textile#additional-information
// Note that using a higher value emits a warning.
const maxNumRewindMessages = 100;

export function createAblyHandler(options: AblyHandlerOptions) {
  const { ably, fetchOperation } = options;

  const isAnonymousClient = () =>
    !ably.auth.clientId || ably.auth.clientId === "*";

  return (
    operation: object,
    variables: object,
    cacheConfig: object,
    observer: Observer,
  ) => {
    /**
     *  Handle an error by reporting it to the subscription
     */
    function handleError(error: unknown) {
      observer.onError(
        error instanceof Error ? error : new Error(String(error)),
      );
    }

    /**
     *  Handle a message by forwarding it to the subscription
     */
    function handleMessage(message: Message) {
      const { result, more } = message.data;

      // TODO: validate result and warn or error if it doesn't have the right
      // shape or is missing.

      if (result) {
        if (result.errors) {
          // FIXME: perhaps we should log these instead, or report them on some
          // other side channel.
          observer.onError(new PayloadErrorsError(result.errors));
        }

        if (result.data && Object.keys(result.data).length > 0) {
          observer.onNext({ data: result.data });
        }
      }

      if (!more) {
        observer.onCompleted();
      }
    }

    /**
     *  Release the given Ably channel.
     */
    async function releaseChannel(channel: RealtimeChannel) {
      try {
        // Deregister all event listeners.
        channel.unsubscribe();

        if (channel.state !== "failed") {
          await channel.detach();
        }
      } catch (error) {
        handleError(error);
      }

      // Even if detaching failed, try releasing the channel now (the failure
      // might have left the channel in FAILED state and it _can_ be released in
      // that state.)
      try {
        ably.channels.release(channel.name);
      } catch (error) {
        handleError(error);
      }
    }

    // This promise resolves to a RealtimeChannel if the subscription was set up
    // successfully, null otherwise.
    let channelPromise: Promise<RealtimeChannel | null> | null = (async () => {
      try {
        // ---------- Initiate subscription

        // POST the subscription like a normal query.
        const response = await fetchOperation(
          operation,
          variables,
          cacheConfig,
        );

        // Extract channel name from response headers.
        const channelName = response.headers.get("X-Subscription-ID");
        if (!channelName) {
          throw new Error("Missing X-Subscription-ID header");
        }

        // Extract optional encryption key from response headers.
        const channelKey = response.headers.get("X-Subscription-Key");

        // ---------- Create Ably channel

        const channel = ably.channels.get(channelName, {
          params: { rewind: String(maxNumRewindMessages) },
          cipher: channelKey ? { key: channelKey } : undefined,
          modes: ["SUBSCRIBE", "PRESENCE"],
        });

        try {
          // ---------- Forward channel failures

          channel.on("failed", (stateChange: ChannelStateChange) => {
            observer.onError(
              stateChange.reason ||
                new Error("Ably channel changed to failed state"),
            );
          });

          // ---------- Forward channel suspension in certain situations

          channel.on("suspended", (stateChange: ChannelStateChange) => {
            // Note: suspension can be a temporary condition and isn't necessarily
            // an error, however we handle the case where the channel gets
            // suspended before it is attached because that's the only way to
            // propagate error 90010 (see https://help.ably.io/error/90010)
            if (
              stateChange.previous === "attaching" &&
              stateChange.current === "suspended" &&
              // Ably channels go into suspended state when they are being
              // detached while attaching, which serves as a backoff period before
              // retrying attachment. This is a harmless condition and therefore
              // we don't raise it.  See:
              // https://ably.com/docs/sdk/js/v2.0/types/ably.ChannelStates.SUSPENDED.html
              // https://github.com/ably/ably-js/blob/471cdef3a52bc95282a570ed910b2ddccfd01436/src/common/lib/client/realtimechannel.ts#L543-L546
              !(
                stateChange.reason?.code === 90001 &&
                stateChange.reason.statusCode === 404
              )
            ) {
              observer.onError(
                stateChange.reason ||
                  new Error("Ably channel suspended before being attached"),
              );
            }
          });

          // ---------- Register presence

          // Register presence, so that we can detect empty channels and clean
          // them up server-side.
          if (isAnonymousClient()) {
            await channel.presence.enterClient(anonymousClientId, "subscribed");
          } else {
            await channel.presence.enter("subscribed");
          }

          // ---------- Finalize subscription

          // Subscribe to incoming messages.
          await channel.subscribe("update", handleMessage);

          // Dispatch the initial update (received in the POST response).
          //
          // This constructs a synthetic message (as would be received from Ably)
          // so that we can reuse the very same codepath.
          handleMessage({ data: { result: response.body, more: true } });

          // Done setting up subscription.
          return channel;
        } catch (error) {
          // If an error happened AFTER creating the channel, report it and
          // release the channel. Return null so that dispose() knows there's no
          // further clean-up to do.
          handleError(error);
          await releaseChannel(channel);
          return null;
        }
      } catch (error) {
        // If an error happened BEFORE creating the channel, report it. Return
        // null so that dispose() knows there's no clean-up to do.
        handleError(error);
        return null;
      }
    })();

    return {
      dispose: async () => {
        // Guard against double disposal
        if (!channelPromise) {
          return;
        }

        const channel = await channelPromise;
        channelPromise = null;

        // Nothing to do if initialization failed.
        if (!channel) {
          return;
        }

        // Release channel and report any errors.
        try {
          await releaseChannel(channel);
        } catch (error) {
          handleError(error);
        }
      },
    };
  };
}
