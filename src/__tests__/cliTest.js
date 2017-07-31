var childProcess = require("child_process")

describe("CLI", () => {
  it("exits 1 on error", () => {
    expect(() => {
      childProcess.execSync("./src/cli.js sync", {stdio: "pipe"})
    }).toThrow("URL must be provided for sync")
  })

  it("exits 0 on OK", () => {
    childProcess.execSync("./src/cli.js sync -h", {stdio: "pipe"})
  })
})
