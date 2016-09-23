GraphQL::Directive::IncludeDirective = GraphQL::Directive.define do
  name "include"
  description "Include this part of the query if `if` is true"
  locations([GraphQL::Directive::FIELD, GraphQL::Directive::FRAGMENT_SPREAD, GraphQL::Directive::INLINE_FRAGMENT])
  argument :if, !GraphQL::BOOLEAN_TYPE
end
