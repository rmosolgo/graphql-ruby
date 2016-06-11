GraphQL::Directive::StreamDirective = GraphQL::Directive.define do
  name "stream"
  description "Push items from this list in sequential patches"
  locations([GraphQL::Directive::FIELD])
end
