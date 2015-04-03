class GraphQL::Types::DateType < GraphQL::Node
  exposes "Date"
  type :date
  field.number(:year)
  field.number(:month)
  field.number(:day)
end