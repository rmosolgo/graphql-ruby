GraphQL::IncludeDirective = GraphQL::Directive.new do |d, type, field, arg|
  d.name "include"
  d.description "Include this part of the query if `if` is true"
  d.on([GraphQL::Directive::ON_FIELD, GraphQL::Directive::ON_FRAGMENT])
  d.arguments({
    if: arg.build({type: !GraphQL::BOOLEAN_TYPE})
  })
  d.resolve -> (arguments, proc) {
    if arguments["if"]
      proc.call
    else
      nil
    end
  }
end
