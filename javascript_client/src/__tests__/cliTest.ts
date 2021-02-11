var childProcess = require("child_process")

describe("CLI", () => {
  it("exits 1 on error", () => {
    expect(() => {
      childProcess.execSync("node ./dist/cli.js sync", {stdio: "pipe"})
    }).toThrow("Client name must be provided for sync")
  })

  it("exits 0 on OK", () => {
    childProcess.execSync("node ./dist/cli.js sync -h", {stdio: "pipe"})
  })
})
