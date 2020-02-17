import graphqlRubyClient from "../index"

it("exports the sync function", () => {
  expect(graphqlRubyClient.sync).toBeInstanceOf(Function)
})
