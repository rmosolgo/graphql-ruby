var childProcess = require("child_process")

function runCommand(commandStr: string) {
  var buffer = childProcess.execSync(commandStr, {stdio: "pipe"})
  return buffer.toString().replace(/\x1b\[[0-9;]*m/g, "")
}
describe("ESM build", () => {
  beforeAll(() => {
    runCommand("npm pack --dry-run")
  })

  it("Can import ESM modules", () => {
    const importResult = runCommand("node --input-type=module -e 'import { sync, ActionCableLink } from \"graphql-ruby-client\"; console.log(typeof sync, typeof ActionCableLink)'")
    expect(importResult).toEqual("function function\n")

    const importResult2 = runCommand("node --input-type=module -e 'import ActionCableLink from \"graphql-ruby-client/subscriptions/ActionCableLink.js\"; console.log(typeof ActionCableLink)'")
    expect(importResult2).toEqual("function\n")
  })

  it("Can require", () => {
    const requireResult = runCommand("node -e 'const ActionCableLink = require(\"graphql-ruby-client/subscriptions/ActionCableLink.js\"); console.log(typeof ActionCableLink.default || typeof ActionCableLink)'")
    expect(requireResult).toEqual("function\n")
    const requireResult2 = runCommand("node -e 'require.resolve(\"graphql-ruby-client/cli.js\"); console.log(\"ok\")'")
    expect(requireResult2).toEqual("ok\n")
  })
})
