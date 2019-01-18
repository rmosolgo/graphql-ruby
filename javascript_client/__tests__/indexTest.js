var graphqlRubyClient = require("../src/index.js")

it("exports the sync function", () => {
  expect(graphqlRubyClient.sync).toBeInstanceOf(Function)
})
