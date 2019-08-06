var { generateClient } = require("../generateClient")

it("returns generated code", function() {
  var code = generateClient({
    path: "./__tests__/documents/*.graphql",
    client: "test-client",
  })
  expect(code).toMatchSnapshot()
})
