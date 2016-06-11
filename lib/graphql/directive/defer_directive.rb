GraphQL::Directive::DeferDirective = GraphQL::Directive.define do
  name "defer"
  description "Push this part of the query in a later patch"
  locations([GraphQL::Directive::FIELD, GraphQL::Directive::FRAGMENT_SPREAD, GraphQL::Directive::INLINE_FRAGMENT])
end
