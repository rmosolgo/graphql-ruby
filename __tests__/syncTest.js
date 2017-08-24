var sync = require("../sync")
var fs = require("fs")
var nock = require("nock")
var Logger = require("../sync/logger")
var logger = new Logger

describe("sync operations", () => {
  beforeEach(() => {
    global.console.error = jest.fn()
    global.console.log = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks();
  })

  describe("custom HTTP options", () => {
    it("uses the provided `send` option & provided URL", () => {
      var url = null
      var options = {
        client: "test-1",
        path: "./__tests__/documents",
        url: "bogus",
        quiet: true,
        send: (sendPayload, options) => {
          url = options.url
        },
      }
      sync(options)

      expect(url).toEqual("bogus")
    })
  })

  describe("custom file processing options", () => {
    it("Adds .graphql to the glob if needed", () => {
      var payload = null
      var options = {
        client: "test-1",
        path: "./__tests__/documents",
        url: "bogus",
        quiet: true,
        send: (sendPayload, opts) => { payload = sendPayload },
      }
      sync(options)

      // Digest::MD5.hexdigest("query GetStuff {\n  stuff\n}\n")
      // => "f7f65309043352183e905e1396e51078"
      var expectedOperations = [
        {
          alias: "f7f65309043352183e905e1396e51078",
          name: "GetStuff",
          body: "query GetStuff {\n  stuff\n}\n",
        }
      ]
      expect(payload.operations).toEqual(expectedOperations)

      options.glob += "**/*.graphql"
      sync(options)
      // Get the same result, even when the glob already has a file extension
      expect(payload.operations).toEqual(expectedOperations)
    })

    it("Uses a custom hash function if provided", () => {
      var payload = null
      var options = {
        client: "test-1",
        path: "./__tests__/documents",
        url: "bogus",
        quiet: true,
        hash: (graphQLBody) => {
          // This is a bad hack to get the operation name
          return graphQLBody.match(/query ([A-Za-z]+) \{/)[1].toUpperCase()
        },
        send: (sendPayload, opts) => { payload = sendPayload },
      }
      sync(options)

      expectedOperations = [
        {
          "body": "query GetStuff {\n  stuff\n}\n",
          "alias": "GETSTUFF",
          "name": "GetStuff",
        },
      ]

      expect(payload.operations).toEqual(expectedOperations)
    })
  })

  describe("Relay support", () => {
    it("Uses Relay output", () => {
      var payload = null
      var options = {
        client: "test-1",
        quiet: true,
        path: "./__generated__",
        url: "bogus",
        send: (sendPayload, opts) => { payload = sendPayload },
      }
      sync(options)

      expectedOperations = [
        {
          "body": "query AppFeedQuery {\n  feed(type: NEW, limit: 5) {\n    ...Feed\n  }\n}\n\nfragment Feed on Entry {\n  repository {\n    owner {\n      login\n    }\n    name\n  }\n  ...FeedEntry\n}\n\nfragment FeedEntry on Entry {\n  repository {\n    owner {\n      login\n    }\n    name\n    stargazers_count\n  }\n  postedBy {\n    login\n  }\n}\n",
          "name": "AppFeedQuery",
          "alias": "353e010cb78d082b29cb63ee7e9027b3",
        },
      ]

      expect(payload.operations).toEqual(expectedOperations)
    })
  })

  describe("Input files", () => {
    it("Merges fragments and operations across files", () => {
      var payload = null
      var options = {
        client: "test-1",
        quiet: true,
        path: "./__tests__/project/",
        url: "bogus",
        // mode: "project" is the default
        send: (sendPayload, opts) => { payload = sendPayload },
      }
      sync(options)

      expectedAliases = [
        "5f0da489cf508a7c65ff5fa144e50545",
        "c944b08d15eb94cf93dd124b7d664b62",
      ]

      expectedNames = ["GetStuff", "GetStuff2"]

      expect(payload.operations.map((op) => op.name)).toEqual(expectedNames)
      expect(payload.operations.map((op) => op.alias)).toEqual(expectedAliases)
    })

    it("Uses mode: file to process each file separately", () => {
      var payload = null
      var options = {
        client: "test-1",
        quiet: true,
        path: "./__tests__/project",
        url: "bogus",
        mode: "file",
        send: (sendPayload, opts) => { payload = sendPayload },
      }
      sync(options)

      // One alias per file, different than above
      expectedAliases = [
        "26c44bfe42872860da112b6177355bfa",
        "7de9e7bf1d6ea1f527de07a25983086c",
        "8bc9b9922a7fbb66f4ac6c58d5d5c357",
        "0a6add7303775e2487f2c2235ecb1c80",
        "2f26b770ded2a04279bc4bf824ca54ac",
      ]

      expectedNames = [null, null, null, "GetStuff", "GetStuff2"]

      expect(payload.operations.map((op) => op.name)).toEqual(expectedNames)
      expect(payload.operations.map((op) => op.alias)).toEqual(expectedAliases)
    })
  })

  describe("Sync output", () => {
    it("Generates a usable artifact for middleware", () => {
      var options = {
        client: "test-1",
        path: "./__tests__/project",
        url: "bogus",
        quiet: true,
        send: (sendPayload, opts) => { },
      }
      sync(options)

      var generatedCode = fs.readFileSync("./OperationStoreClient.js", "utf8")
      expect(generatedCode).toMatch('"GetStuff": "5f0da489cf508a7c65ff5fa144e50545"')
      expect(generatedCode).toMatch('module.exports = OperationStoreClient')
      expect(generatedCode).toMatch('var _client = "test-1"')
      fs.unlinkSync("./OperationStoreClient.js")
    })

    it("Takes an outfile option", () => {
      var options = {
        client: "test-2",
        path: "./__tests__/project",
        url: "bogus",
        quiet: true,
        outfile: "__crazy_outfile.js",
        send: (sendPayload, opts) => { },
      }
      sync(options)

      var generatedCode = fs.readFileSync("./__crazy_outfile.js", "utf8")
      expect(generatedCode).toMatch('"GetStuff": "5f0da489cf508a7c65ff5fa144e50545"')
      expect(generatedCode).toMatch('module.exports = OperationStoreClient')
      expect(generatedCode).toMatch('var _client = "test-2"')
      fs.unlinkSync("./__crazy_outfile.js")
    })
  })

  describe("Logging", () => {
    it("Logs progress", () => {
      var spy = console.log

      var options = {
        client: "test-1",
        path: "./__tests__/project",
        url: "bogus",
        send: (sendPayload, opts) => { },
      }
      sync(options)

      var expectedCalls = [
        ["Syncing 2 operations to " + logger.bright("bogus") + "..."],
        ["Generating client module in " + logger.bright("OperationStoreClient.js") + "..."],
        [logger.green("✓ Done!")],
      ]

      expect(spy.mock.calls).toEqual(expectedCalls)
    })

    it("Can be quieted with quiet: true", () => {
      var spy = console.log

      var options = {
        client: "test-1",
        path: "./__tests__/project",
        url: "bogus",
        quiet: true,
        send: (sendPayload, opts) => { },
      }
      sync(options)

      var expectedCalls = []
      expect(spy.mock.calls).toEqual(expectedCalls)
    })
  })

  describe("Printing the result", () => {
    function buildMockRespondingWith(status, data) {
      return nock("http://example.com").post("/stored_operations/sync").reply(status, data)
    }

    it("prints failure", () => {
      var spyConsoleLog = console.log
      var spyConsoleError = console.error

      var mock = buildMockRespondingWith(422, {
        errors: { "5f0da489cf508a7c65ff5fa144e50545": ["something"] },
        failed: ["5f0da489cf508a7c65ff5fa144e50545"],
        added: ["defg"],
        not_modified: [],
      })

      var options = {
        client: "test-1",
        path: "./__tests__/project",
        url: "http://example.com/stored_operations/sync",
        quiet: false,
      }

      var syncPromise = sync(options)

      return syncPromise.then(() => {

        var expectedLogCalls = [
          ["Syncing 2 operations to " + logger.bright("http://example.com/stored_operations/sync") + "..."],
          ["  " + logger.dim("0 added")],
          ["  " + logger.dim("0 not modified")],
          ["  " + logger.red("1 failed")]
        ]

        var expectedErrorCalls = [
          ["Sync failed, errors:"],
          ["  GetStuff:"],
          ["    " + logger.red("✘") + " something"],
        ]
        expect(spyConsoleLog.mock.calls).toEqual(expectedLogCalls)
        expect(spyConsoleError.mock.calls).toEqual(expectedErrorCalls)
        jest.clearAllMocks();
      })
    })

    it("prints success", () => {
      var spyConsoleLog = console.log
      var spyConsoleError = console.error

      var mock = buildMockRespondingWith(422, {
        errors: {},
        failed: [],
        added: ["defg"],
        not_modified: ["xyz", "123"],
      })

      var options = {
        client: "test-1",
        path: "./__tests__/project",
        url: "http://example.com/stored_operations/sync",
        quiet: false,
      }

      var syncPromise = sync(options)

      var expectedLogCalls = [
        ["Syncing 2 operations to " + logger.bright("http://example.com/stored_operations/sync") + "..."],
      ]
      expect(spyConsoleLog.mock.calls).toEqual(expectedLogCalls)
      jest.clearAllMocks();

      return syncPromise.then(() => {
        var expectedLogCalls = [
          ["  " + logger.green("1 added")],
          ["  " + logger.reset("2 not modified")],
          ["  " + logger.dim("0 failed")],
          ["Generating client module in " + logger.bright("OperationStoreClient.js") + "..."],
          [logger.green("✓ Done!")],
        ]
        var expectedErrorCalls = []
        expect(spyConsoleLog.mock.calls).toEqual(expectedLogCalls)
        expect(spyConsoleError.mock.calls).toEqual(expectedErrorCalls)
        jest.clearAllMocks();
      })
    })
  })
})
