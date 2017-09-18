jest.dontMock('nock');
var nock = require('nock');
var sendPayload = require("../sendPayload")

describe("Posting GraphQL to OperationStore Endpoint", () => {
  it("Posts to the specified URL", () => {
    var mock = nock("http://example.com")
      .post("/stored_operations/sync")
      .reply(200, { "ok" : "ok" })

    return sendPayload("payload", { url: "http://example.com/stored_operations/sync" }).then(function() {
      expect(mock.isDone()).toEqual(true)
    })
  })

  it("Returns the response JSON to the promise", () => {
    var mock = nock("http://example.com")
      .post("/stored_operations/sync")
      .reply(200, { result: "ok" })

    return sendPayload("payload", { url: "http://example.com/stored_operations/sync" }).then(function(response) {
      expect(response).toEqual('{"result":"ok"}')
    })
  })

  it("Adds an hmac-sha256 header if key is present", () => {
    var payload = { "payload": [1,2,3] }
    var key = "2f26b770ded2a04279bc4bf824ca54ac"
    // ruby -ropenssl -e 'puts OpenSSL::HMAC.hexdigest("SHA256", "2f26b770ded2a04279bc4bf824ca54ac", "{\"payload\":[1,2,3]}")'
    // f6eab31abc2fa446dbfd2e9c10a778aaffd4d0c1d62dd9513d6f7ea60557987c
    var signature = "f6eab31abc2fa446dbfd2e9c10a778aaffd4d0c1d62dd9513d6f7ea60557987c"
    var mock = nock("http://example.com", {
      reqheaders: {
        'authorization': 'GraphQL::Pro Abc ' + signature
      }})
      .post("/stored_operations/sync")
      .reply(200, { result: "ok" })

    var opts = {secret: key, client: "Abc", url: "http://example.com/stored_operations/sync"}
    return sendPayload(payload, opts).then(function(response) {
      expect(response).toEqual('{"result":"ok"}')
      expect(mock.isDone()).toEqual(true)
    })
  })
})
