import { visit, ASTNode, FieldNode, parse, print } from "graphql"


function removeIfClient(node: FieldNode): undefined | null {
  const clientDirective = node.directives?.find((directiveNode) => { return directiveNode.name.value == "client" })
  if (clientDirective) {
    return null
  } else {
    return undefined
  }
}

function removeClientFields(node: ASTNode) {
  var visitor = {
    Field: {
      leave: removeIfClient,
    }
  }
  return visit(node, visitor)
}

function removeClientFieldsFromString(body: string): string {
  const ast = parse(body)
  const newAst = removeClientFields(ast)
  return print(newAst)
}

export {
  removeClientFields,
  removeClientFieldsFromString
}
