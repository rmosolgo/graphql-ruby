var graphqlRubyClient = require("../src/sync/main.js")

it("exports the sync function", () => {
  expect(graphqlRubyClient.sync).toBeInstanceOf(Function)
})
