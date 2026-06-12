// `crypto.randomUUID` is only exposed in secure contexts (HTTPS or localhost),
// so fall back to `crypto.getRandomValues` — available in all contexts — to
// keep subscriptions working on plain-HTTP origins with the same 128 bits of
// entropy. (https://github.com/rmosolgo/graphql-ruby/issues/5648)
function defaultChannelId(): string {
  if (typeof crypto.randomUUID === "function") {
    return crypto.randomUUID()
  }

  return Array.from(
    crypto.getRandomValues(new Uint8Array(16)),
    (byte) => byte.toString(16).padStart(2, "0")
  ).join("")
}

export default defaultChannelId
