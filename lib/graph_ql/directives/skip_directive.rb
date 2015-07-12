GraphQL::SkipDirective = GraphQL::Directive.new do |d|
  d.name 'skip'
  d.description 'Ignore this part of the query if `if` is true'
  d.on([GraphQL::Directive::ON_FIELD, GraphQL::Directive::ON_FRAGMENT])
  d.arguments(if: d.arg(type: !GraphQL::BOOLEAN_TYPE))
  d.resolve lambda  { |arguments, proc|
    proc.call unless arguments['if']
  }
end
