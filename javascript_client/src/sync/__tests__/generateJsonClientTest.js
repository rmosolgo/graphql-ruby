var { generateClientCode, JSON_TYPE } = require("../generateClient")
var fs = require("fs")

function withExampleClient(mapName, callback) {
  // Generate some code and write it to a file
  var exampleOperations = [
    {name: "a", alias: "b"},
    {name: "c-d", alias: "e-f"}
  ]

  var json = generateClientCode("example-client", exampleOperations, JSON_TYPE)
  var filename = "./" + mapName + ".json"
  fs.writeFileSync(filename, json)

  // Run callback with generated client
  callback(json)

  // Clean up the generated file
  fs.unlinkSync(filename)
}

it("generates a valid json object string that maps names to operations", () => {
  withExampleClient("map1", (json) => {
    expect(json).toMatchSnapshot() // String version
    expect(JSON.parse(json)).toMatchSnapshot() // Object version (i.e., valid JSON)
  })
})
