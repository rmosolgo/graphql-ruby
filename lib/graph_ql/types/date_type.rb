class GraphQL::Types::DateType < GraphQL::Node
  exposes "Date"
  desc "A given year-month-day"
  type :date
  field.number(:year)
  field.number(:month)
  field.number(:day)
end