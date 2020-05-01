import sync from "../sync"
var fs = require("fs")
var nock = require("nock")

interface MockOperation {
  alias: string,
}

interface MockPayload {
  operations: MockOperation[],
  generatedCode: string,
}

interface MockedObject {
   mock: { calls: object }
}

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
      var url: string
      var options = {
        client: "test-1",
        path: "./src/__tests__/documents",
        url: "bogus",
        quiet: true,
        send: (_sendPayload: object, options: { url: string }) => {
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
      var spy = (console.log as unknown) as MockedObject
      var options = {
        client: "test-1",
        path: "./src/__tests__/documents",
        url: "bogus",
        verbose: true,
        send: (_sendPayload: string, opts: { verbose: boolean }) => {
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
      var payload: MockPayload
      var options = {
        client: "test-1",
        path: "./src/__tests__/documents",
        url: "bogus",
        quiet: true,
        send: (sendPayload: MockPayload, _opts: object) => { payload = sendPayload },
      }
      return sync(options).then(function() {
        expect(payload.operations).toMatchSnapshot()

        var optionsWithExt = {...options, glob: "./**/*.graphql"}
        return sync(optionsWithExt).then(function() {
          // Get the same result, even when the glob already has a file extension
          expect(payload.operations).toMatchSnapshot()
        })
      })
    })

    it("Uses a custom hash function if provided", () => {
      var payload: MockPayload
      var options = {
        client: "test-1",
        path: "./src/__tests__/documents",
        url: "bogus",
        quiet: true,
        hash: (graphQLBody: string) => {
          // This is a bad hack to get the operation name
          var opName = graphQLBody.match(/query ([A-Za-z]+) \{/)
          return opName ? opName[1].toUpperCase() : null
        },
        send: (sendPayload: MockPayload, _opts: object) => { payload = sendPayload },
      }
      return sync(options).then(function() {
        expect(payload.operations).toMatchSnapshot()
      })
    })
  })

  describe("Relay support", () => {
    it("Uses Relay generated .js files", () => {
      var payload: MockPayload
      var options = {
        client: "test-1",
        quiet: true,
        path: "./src/__generated__",
        url: "bogus",
        send: (sendPayload: MockPayload, _opts: object) => { payload = sendPayload },
      }
      return sync(options).then(function () {
        expect(payload.operations).toMatchSnapshot()
      })
    })

    it("Uses relay --persist-output JSON files", () => {
      var payload: MockPayload
      var options = {
        client: "test-1",
        quiet: true,
        relayPersistedOutput: "./src/__tests__/example-relay-persisted-queries.json",
        url: "bogus",
        send: (sendPayload: MockPayload, _opts: object) => {
          payload = sendPayload
        },
      }
      return sync(options).then(function () {
        return expect(payload.operations).toMatchSnapshot()
      })
    })

    it("Uses Apollo Android OperationOutput JSON files", () => {
      var payload: MockPayload
      var options = {
        client: "test-1",
        quiet: true,
        apolloAndroidOperationOutput: "./src/__tests__/example-apollo-android-operation-output.json",
        url: "bogus",
        send: (sendPayload: MockPayload, _opts: object) => {
          payload = sendPayload
        },
      }
      return sync(options).then(function () {
        expect(payload.operations[0].alias).toEqual("aba626ea9bdf465954e89e5590eb2c1a")
        return expect(payload.operations).toMatchSnapshot()
      })
    })
  })

  describe("Input files", () => {
    it("Merges fragments and operations across files", () => {
      var payload: MockPayload
      var options = {
        client: "test-1",
        quiet: true,
        path: "./src/__tests__/project/",
        url: "bogus",
        // mode: "project" is the default
        send: (sendPayload: MockPayload, _opts: object) => { payload = sendPayload },
      }
      return sync(options).then(function () {
        expect(payload.operations).toMatchSnapshot()
      })
    })

    it("Uses mode: file to process each file separately", () => {
      var payload: MockPayload
      var options = {
        client: "test-1",
        quiet: true,
        path: "./src/__tests__/project",
        url: "bogus",
        mode: "file",
        send: (sendPayload: MockPayload, _opts: object) => { payload = sendPayload },
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
        path: "./src/__tests__/project",
        url: "bogus",
        quiet: true,
        send: () => { },
      }

      return sync(options).then(function(ppayload: unknown) {
        var payload = ppayload as MockPayload
        expect(payload.operations.length).toEqual(5)
        var generatedCode = fs.readFileSync("./src/OperationStoreClient.js", "utf8")
        expect(payload.generatedCode).toEqual(generatedCode)
        fs.unlinkSync("./src/OperationStoreClient.js")
      })
    })
  })
  describe("Sync output", () => {
    it("Generates a usable artifact for middleware", () => {
      var options = {
        client: "test-1",
        path: "./src/__tests__/project",
        url: "bogus",
        quiet: true,
        send: () => { },
      }
      return sync(options).then(function() {
        var generatedCode = fs.readFileSync("./src/OperationStoreClient.js", "utf8")
        expect(generatedCode).toMatch('"GetStuff": "5f0da489cf508a7c65ff5fa144e50545"')
        expect(generatedCode).toMatch('module.exports = OperationStoreClient')
        expect(generatedCode).toMatch('var _client = "test-1"')
        fs.unlinkSync("./src/OperationStoreClient.js")
      })
    })

    it("Takes an outfile option", () => {
      var options = {
        client: "test-2",
        path: "./src/__tests__/project",
        url: "bogus",
        quiet: true,
        outfile: "__crazy_outfile.js",
        send: () => { },
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
        relayPersistedOutput: "./src/__tests__/example-relay-persisted-queries.json",
        url: "bogus",
        quiet: true,
        send: () => { },
      }
      return sync(options).then(function() {
        // This is the default outfile:
        var wasWritten = fs.existsSync("./src/OperationStoreClient.js")
        expect(wasWritten).toBe(false)
      })
    })

    it("Skips outfile generation when using --apollo-android-operation-output artifact", () => {
      var options = {
        client: "test-2",
        apolloAndroidOperationOutput: "./src/__tests__/example-apollo-android-operation-output.json",
        url: "bogus",
        quiet: true,
        send: () => { },
      }
      return sync(options).then(function() {
        // This is the default outfile:
        var wasWritten = fs.existsSync("./src/OperationStoreClient.js")
        expect(wasWritten).toBe(false)
      })
    })
  })

  describe("Logging", () => {
    it("Logs progress", () => {
      var spy = (console.log as unknown) as MockedObject

      var options = {
        client: "test-1",
        path: "./src/__tests__/project",
        url: "bogus",
        send: () => { },
      }
      return sync(options).then(function() {
        expect(spy.mock.calls).toMatchSnapshot()
      })
    })

    it("Can be quieted with quiet: true", () => {
      var spy = (console.log as unknown) as MockedObject

      var options = {
        client: "test-1",
        path: "./src/__tests__/project",
        url: "bogus",
        quiet: true,
        send: () => { },
      }
      return sync(options).then(function() {
        expect(spy.mock.calls).toMatchSnapshot()
      })
    })
  })

  describe("Printing the result", () => {
    function buildMockRespondingWith(status: number, data: object) {
      return nock("http://example.com").post("/stored_operations/sync").reply(status, data)
    }

    it("prints failure and sends the message to the promise", () => {
      var spyConsoleLog = (console.log as unknown) as MockedObject
      var spyConsoleError = (console.error as unknown) as MockedObject

      buildMockRespondingWith(422, {
        errors: { "5f0da489cf508a7c65ff5fa144e50545": ["something"] },
        failed: ["5f0da489cf508a7c65ff5fa144e50545"],
        added: ["defg"],
        not_modified: [],
      })

      var options = {
        client: "test-1",
        path: "./src/__tests__/project",
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
      var spyConsoleLog = (console.log as unknown) as MockedObject
      var spyConsoleError = (console.error as unknown) as MockedObject

      buildMockRespondingWith(422, {
        errors: {},
        failed: [],
        added: ["defg"],
        not_modified: ["xyz", "123"],
      })

      var options = {
        client: "test-1",
        path: "./src/__tests__/project",
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
