# frozen_string_literal: true
GraphQL::Directive::SkipDirective = GraphQL::Directive.define do
  name "skip"
  description "Directs the executor to skip this field or fragment when the `if` argument is true."
  locations([GraphQL::Directive::FIELD, GraphQL::Directive::FRAGMENT_SPREAD, GraphQL::Directive::INLINE_FRAGMENT])

  argument :if, !GraphQL::BOOLEAN_TYPE, 'Skipped when true.'
  default_directive true
end
