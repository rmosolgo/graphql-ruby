GraphQL::SkipDirective = GraphQL::Directive.new do |d|
  d.name "skip"
  d.description "Ignore this part of the query if `if` is true"
  d.on([GraphQL::Directive::ON_FIELD, GraphQL::Directive::ON_FRAGMENT])
  d.arguments({
    if: {type: !GraphQL::BOOLEAN_TYPE}
  })
  d.resolve -> (arguments, proc) {
    if !arguments["if"]
      proc.call
    else
      nil
    end
  }
end
