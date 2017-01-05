# frozen_string_literal: true
GraphQL::Directive::IncludeDirective = GraphQL::Directive.define do
  name "include"
  description "Directs the executor to include this field or fragment only when the `if` argument is true."
  locations([GraphQL::Directive::FIELD, GraphQL::Directive::FRAGMENT_SPREAD, GraphQL::Directive::INLINE_FRAGMENT])
  argument :if, !GraphQL::BOOLEAN_TYPE, 'Included when true.'
  default_directive true
end
