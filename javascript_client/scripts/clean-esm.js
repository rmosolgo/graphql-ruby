const fs = require("fs")
const path = require("path")

const esmRoot = path.join(__dirname, "..", "esm")

fs.rmSync(esmRoot, { recursive: true, force: true })
fs.mkdirSync(esmRoot, { recursive: true })
