import { generateClient } from "../generateClient"
import md5 from "../md5"
it("returns generated code", function() {
  var code = generateClient({
    path: "./src/__tests__/documents/*.graphql",
    client: "test-client",
    // TODO -- i think some people might use the direct API here, reconsider requiring these.
    mode: "project",
    hash: md5,
    addTypename: true,
    clientType: "js",
    verbose: false,
  })
  expect(code).toMatchSnapshot()
})
