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
      return sync(options).then(function() {
        expect(url).toEqual("bogus")
      })
    })
  })

  describe("verbose", () => {
    it("Adds debug output", () => {
      var spy = console.log
      var payload = null
      var options = {
        client: "test-1",
        path: "./__tests__/documents",
        url: "bogus",
        verbose: true,
        send: (sendPayload, opts) => {
          payload = sendPayload
          if (opts.verbose) {
            console.log("Verbose!")
          }
        },
      }
      return sync(options).then(function() {
        expect(spy.mock.calls).toMatchSnapshot()
      })
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
      return sync(options).then(function() {
        expect(payload.operations).toMatchSnapshot()

        options.glob += "**/*.graphql"
        return sync(options).then(function() {
          // Get the same result, even when the glob already has a file extension
          expect(payload.operations).toMatchSnapshot()
        })
      })
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
      return sync(options).then(function() {
        expect(payload.operations).toMatchSnapshot()
      })
    })
  })

  describe("Relay support", () => {
    it("Uses Relay generated .js files", () => {
      var payload = null
      var options = {
        client: "test-1",
        quiet: true,
        path: "./__generated__",
        url: "bogus",
        send: (sendPayload, opts) => { payload = sendPayload },
      }
      return sync(options).then(function () {
        expect(payload.operations).toMatchSnapshot()
      })
    })

    it("Uses relay --persist-output JSON files", () => {
      var payload = null
      var options = {
        client: "test-1",
        quiet: true,
        relayPersistedOutput: "./__tests__/example-relay-persisted-queries.json",
        url: "bogus",
        send: (sendPayload, opts) => {
          console.log(payload)
          payload = sendPayload
        },
      }
      return sync(options).then(function () {
        return expect(payload.operations).toMatchSnapshot()
      })
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
      return sync(options).then(function () {
        expect(payload.operations).toMatchSnapshot()
      })
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
      return sync(options).then(function() {
        expect(payload.operations).toMatchSnapshot()
      })
    })
  })

  describe("Promise result", () => {
    it("Yields the payload and generated code", () => {
      var options = {
        client: "test-1",
        path: "./__tests__/project",
        url: "bogus",
        quiet: true,
        send: (sendPayload, opts) => { },
      }

      return sync(options).then(function(payload) {
        expect(payload.operations.length).toEqual(5)
        var generatedCode = fs.readFileSync("./OperationStoreClient.js", "utf8")
        expect(payload.generatedCode).toEqual(generatedCode)
        fs.unlinkSync("./OperationStoreClient.js")
      })
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
      return sync(options).then(function() {
        var generatedCode = fs.readFileSync("./OperationStoreClient.js", "utf8")
        expect(generatedCode).toMatch('"GetStuff": "5f0da489cf508a7c65ff5fa144e50545"')
        expect(generatedCode).toMatch('module.exports = OperationStoreClient')
        expect(generatedCode).toMatch('var _client = "test-1"')
        fs.unlinkSync("./OperationStoreClient.js")
      })
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
      return sync(options).then(function() {
        var generatedCode = fs.readFileSync("./__crazy_outfile.js", "utf8")
        expect(generatedCode).toMatch('"GetStuff": "5f0da489cf508a7c65ff5fa144e50545"')
        expect(generatedCode).toMatch('module.exports = OperationStoreClient')
        expect(generatedCode).toMatch('var _client = "test-2"')
        fs.unlinkSync("./__crazy_outfile.js")
      })
    })

    it("Skips outfile generation when using --persist-output artifact", () => {
      var options = {
        client: "test-2",
        relayPersistedOutput: "./__tests__/example-relay-persisted-queries.json",
        url: "bogus",
        quiet: true,
        send: (sendPayload, opts) => { },
      }
      return sync(options).then(function() {
        // This is the default outfile:
        var wasWritten = fs.existsSync("./OperationStoreClient.js")
        expect(wasWritten).toBe(false)
      })
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
      return sync(options).then(function() {
        expect(spy.mock.calls).toMatchSnapshot()
      })
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
      return sync(options).then(function() {
        expect(spy.mock.calls).toMatchSnapshot()
      })
    })
  })

  describe("Printing the result", () => {
    function buildMockRespondingWith(status, data) {
      return nock("http://example.com").post("/stored_operations/sync").reply(status, data)
    }

    it("prints failure and sends the message to the promise", () => {
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

      return syncPromise.catch((errmsg) => {
        expect(errmsg).toEqual("Sync failed: GetStuff: something")
        expect(spyConsoleLog.mock.calls).toMatchSnapshot()
        expect(spyConsoleError.mock.calls).toMatchSnapshot()
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

      expect(spyConsoleLog.mock.calls).toMatchSnapshot()
      jest.clearAllMocks();

      return syncPromise.then(() => {
        expect(spyConsoleLog.mock.calls).toMatchSnapshot()
        expect(spyConsoleError.mock.calls).toMatchSnapshot()
        jest.clearAllMocks();
      })
    })
  })
})
