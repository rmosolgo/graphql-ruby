var { generateClient } = require("../generateClient")

it("returns generated code", function() {
  var code = generateClient({
    path: "./src/sync/__tests__/documents/*.graphql",
    clientName: "test-client",
  })
  expect(code).toMatchSnapshot()
})
