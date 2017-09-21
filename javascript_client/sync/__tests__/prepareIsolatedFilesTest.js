var prepareIsolatedFiles = require("../prepareIsolatedFiles")

it("builds out single operations", () => {
  var filenames = [
    "./__tests__/project/op_isolated_1.graphql",
    "./__tests__/project/op_isolated_2.graphql",
  ]
  var ops = prepareIsolatedFiles(filenames, false)
  expect(ops).toMatchSnapshot()
})

describe("with --add-typename", () => {
  it("builds out single operations with __typename fields", () => {
    var filenames = [
      "./__tests__/project/op_isolated_1.graphql",
      "./__tests__/project/op_isolated_2.graphql",
    ]
    var ops = prepareIsolatedFiles(filenames, true)
    expect(ops).toMatchSnapshot()
  })
})
