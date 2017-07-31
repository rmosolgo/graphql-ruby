var graphqlPro = require("../index.js")

it("exports the sync function", () => {
  expect(graphqlPro.sync).toBeInstanceOf(Function)
})
