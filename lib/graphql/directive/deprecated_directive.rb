# frozen_string_literal: true
GraphQL::Directive::DeprecatedDirective = GraphQL::Directive.define do
  name "deprecated"
  description "Marks an element of a GraphQL schema as no longer supported."
  locations([GraphQL::Directive::FIELD_DEFINITION, GraphQL::Directive::ENUM_VALUE])

  reason_description = "Explains why this element was deprecated, usually also including a "\
    "suggestion for how to access supported similar data. Formatted "\
    "in [Markdown](https://daringfireball.net/projects/markdown/)."

  argument :reason, GraphQL::STRING_TYPE, reason_description, default_value: GraphQL::Directive::DEFAULT_DEPRECATION_REASON
  default_directive true
end
