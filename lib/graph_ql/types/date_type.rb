class GraphQL::Types::DateType < GraphQL::Node
  exposes "Date"
  desc "A given year-month-day"
  type :date
  field.number(:year, "year")
  field.number(:month, "month of the year")
  field.number(:day, "day of the month")
end