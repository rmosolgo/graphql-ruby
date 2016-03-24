GraphQL::Introspection::DirectiveLocationEnum = GraphQL::EnumType.define do
  name "__DirectiveLocation"
  description "Parts of the query where a directive may be located"

  GraphQL::Directive::LOCATIONS.each do |location|
    value(location.to_s, value: location)
  end
end
