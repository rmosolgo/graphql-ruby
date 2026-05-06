const fs = require("fs")
const path = require("path")

const esmRoot = path.join(__dirname, "..", "esm")

fs.writeFileSync(
  path.join(esmRoot, "package.json"),
  JSON.stringify({ type: "module" }, null, 2) + "\n"
)

for (const filePath of findJavaScriptFiles(esmRoot)) {
  const source = fs.readFileSync(filePath, "utf8")
  const nextSource = source
    .replaceAll("@apollo/client/core\"", "@apollo/client/core/index.js\"")
    .replaceAll("@apollo/client/core'", "@apollo/client/core/index.js'")
    .replaceAll("graphql/language/printer\"", "graphql/language/printer.js\"")
    .replaceAll("graphql/language/printer'", "graphql/language/printer.js'")
    .replace(/(from\s+["'])(\.[^"']+)(["'])/g, function(match, prefix, specifier, suffix) {
      return prefix + resolveRelativeSpecifier(filePath, specifier) + suffix
    })

  if (nextSource !== source) {
    fs.writeFileSync(filePath, nextSource)
  }
}

function findJavaScriptFiles(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(function(entry) {
    const entryPath = path.join(directory, entry.name)

    if (entry.isDirectory()) {
      return findJavaScriptFiles(entryPath)
    }

    return entry.isFile() && entry.name.endsWith(".js") ? [entryPath] : []
  })
}

function resolveRelativeSpecifier(fromPath, specifier) {
  if (path.extname(specifier)) {
    return specifier
  }

  const fromDirectory = path.dirname(fromPath)
  const filePath = path.resolve(fromDirectory, specifier + ".js")
  const indexPath = path.resolve(fromDirectory, specifier, "index.js")

  if (fs.existsSync(filePath)) {
    return specifier + ".js"
  }

  if (fs.existsSync(indexPath)) {
    return specifier + "/index.js"
  }

  return specifier
}
