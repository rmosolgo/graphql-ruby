var { generateClient } = require("../generateClient")

it("returns generated code", function() {
  var code = generateClient({
    path: "./__tests__/documents/*.graphql",
    clientName: "test-client",
  })
  expect(code).toMatchSnapshot()
})
