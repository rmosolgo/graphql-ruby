GraphQL::Directive::SkipDirective = GraphQL::Directive.define do
  name "skip"
  description "Ignore this part of the query if `if` is true"
  locations([GraphQL::Directive::FIELD, GraphQL::Directive::FRAGMENT_SPREAD, GraphQL::Directive::INLINE_FRAGMENT])

  argument :if, !GraphQL::BOOLEAN_TYPE
end
