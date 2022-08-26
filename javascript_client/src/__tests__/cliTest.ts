var childProcess = require("child_process")

describe("CLI", () => {
  it("exits 1 on error", () => {
    expect(() => {
      childProcess.execSync("node ./cli.js sync", {stdio: "pipe"})
    }).toThrow("Client name must be provided for sync")
  })

  it("exits 0 on OK", () => {
    childProcess.execSync("node ./cli.js sync -h", {stdio: "pipe"})
  })

  it("runs with some options", () => {
    var buffer = childProcess.execSync("node ./cli.js sync --client=something --header=Abcd:efgh --header=\"Abc: 123 45\" --mode=file --path=\"**/doc1.graphql\"", {stdio: "pipe"})
    var response = buffer.toString().replace(/\033\[[0-9;]*m/g, "")
    expect(response).toEqual("No URL; Generating artifacts without syncing them\nGenerating client module in src/OperationStoreClient.js...\n✓ Done!\n")
  })
})
