class GraphQL::Types::DateTimeType < GraphQL::Types::DateType
  exposes "DateTime"
  desc("A date with hours, minutes and seconds")
  type :date_time
  field.number(:hour)
  field.number(:min)
  field.number(:sec)
end