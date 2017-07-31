var prepareProject = require("../prepareProject")

describe("merging a project", () => {
  it("builds out separate operations", () => {
    var filenames = [
      "./src/__tests__/project/op_2.graphql",
      "./src/__tests__/project/op_1.graphql",
      "./src/__tests__/project/frag_1.graphql",
      "./src/__tests__/project/frag_2.graphql",
      "./src/__tests__/project/frag_3.graphql",
    ]
    var ops = prepareProject(filenames)

    var expectedOps = [
      {
        body: 'query GetStuff2 {\n  stuff\n  ...Frag1\n  ...Frag2\n}\n\nfragment Frag1 on Query {\n  moreStuff\n}\n\nfragment Frag2 on Query {\n  ...Frag3\n}\n\nfragment Frag3 on Query {\n  evenMoreStuff\n}\n',
        name: 'GetStuff2',
        alias: null,
      },
      {
        body: 'query GetStuff {\n  ...Frag1\n}\n\nfragment Frag1 on Query {\n  moreStuff\n}\n',
        name: 'GetStuff',
        alias: null,
      }
    ]
    expect(ops).toEqual(expectedOps)
  })

  it("blows up on duplicate names", () => {
    var filenames = [
      "./src/__tests__/documents/doc1.graphql",
      "./src/__tests__/project/op_2.graphql",
      "./src/__tests__/project/op_1.graphql",
      "./src/__tests__/project/frag_1.graphql",
    ]
    expect(() => {
      prepareProject(filenames)
    }).toThrow("Found duplicate definition name: GetStuff, fragment & operation names must be unique to sync")
  })
})
