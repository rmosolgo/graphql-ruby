var { generateClient, JS_TYPE } = require("../generateClient")
var fs = require("fs")

function withExampleClient(mapName, callback) {
  // Generate some code and write it to a file
  var exampleMap = { a: "b", "c-d": "e-f" }
  var jsCode = generateClient("example-client", exampleMap, JS_TYPE)
  var filename = "./" + mapName + ".js"
  fs.writeFileSync(filename, jsCode)

  // Load the module and use it
  var exampleModule = require("../../" + mapName)
  callback(exampleModule)

  // Clean up the generated file
  fs.unlinkSync(filename)
}

it("generates a valid JavaScript module that maps names to operations", () => {
  withExampleClient("map1", (exampleClient) => {
    // It does the mapping
    expect(exampleClient.getPersistedQueryAlias("a")).toEqual("b")
    expect(exampleClient.getPersistedQueryAlias("c-d")).toEqual("e-f")
    // It returns a param
    expect(exampleClient.getOperationId("a")).toEqual("example-client/b")
  })
})

it("generates an Apollo middleware", () => {
  withExampleClient("map2", (exampleClient) => {
    var nextWasCalled = false
    var next = () => {
      nextWasCalled = true
    }
    var req = {
      operationName: "a",
      query: "x"
    }

    exampleClient.apolloMiddleware.applyMiddleware({request: req}, next)

    expect(nextWasCalled).toEqual(true)
    expect(req.query).toBeUndefined()
    expect(req.operationId).toEqual("example-client/b")
  })
})

it("generates an Apollo Link", () => {
  var fakeOperation = {
    operationName: "a",
    context: null,
    setContext: function(c) {
      this.context = c
    },
    extensions: {},
  }

  var forwardedOperation = null
  var fakeForward = function(operation) {
    forwardedOperation = operation
  }

  withExampleClient("map3", (exampleClient) => {
    exampleClient.apolloLink(fakeOperation, fakeForward)

    expect(fakeOperation.extensions.operationId).toEqual("example-client/b")
    expect(fakeOperation.context.http).toEqual({includeQuery: false, includeExtensions: true})
    expect(forwardedOperation).toEqua;(fakeOperation)
  })
})
