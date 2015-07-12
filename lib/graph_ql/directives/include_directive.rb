GraphQL::IncludeDirective = GraphQL::Directive.new do |d|
  d.name 'include'
  d.description 'Include this part of the query if `if` is true'
  d.on([GraphQL::Directive::ON_FIELD, GraphQL::Directive::ON_FRAGMENT])
  d.arguments(if: d.arg(type: !GraphQL::BOOLEAN_TYPE))
  d.resolve lambda  { |arguments, proc|
    proc.call if arguments['if']
  }
end
