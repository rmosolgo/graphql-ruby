import PusherLink from "../PusherLink"
import Pusher from 'pusher-js'
import pako from 'pako'

describe("PusherLink", () => {
  it("throws an error when no `decompress:` is configured", () => {
    const link = new PusherLink({
      pusher: new Pusher("123"),
    })

    const observer = {
      next: (_result: object) => {},
      complete: () => {},
    }

    const payload = {
      more: true,
      compressed_result: "abcdef",
    }

    expect(() => {
      link._onUpdate("abc", observer, payload)
    }).toThrow("Received compressed_result but PusherLink wasn't configured with `decompress: (result: string) => any`. Add this configuration.")
  })

  it("decompresses compressed_result", () => {
    const link = new PusherLink({
      pusher: new Pusher("123"),
      decompress: (compressed) => {
        const buff = Buffer.from(compressed, 'base64');
        return JSON.parse(pako.inflate(buff, { to: 'string' }));
       },
    })

    const results: Array<object | string> = []

    const observer = {
      next: (result: object) => { results.push(result) },
      complete: () => { results.push("complete") },
    }

    const compressedData = pako.deflate(JSON.stringify({ a: 1, b: 2}))
    // Browsers have `TextEncoder` for this
    const compressedStr = Buffer.from(compressedData).toString("base64")
    const payload = {
      more: true,
      compressed_result: compressedStr,
    }

    // Send a dummy payload and then terminate the subscription
    link._onUpdate("abc", observer, payload)
    link._onUpdate("abc", observer, { more: false })
    expect(results).toEqual([{a: 1, b: 2}, "complete"])
  })
})
