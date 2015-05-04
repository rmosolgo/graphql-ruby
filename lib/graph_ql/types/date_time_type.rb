class GraphQL::Types::DateTimeType < GraphQL::Types::DateType
  exposes "DateTime"
  desc("A date with hours, minutes and seconds")
  type :date_time
  field.number(:hour, "hour")
  field.number(:min, "minute")
  field.number(:sec, "seconds")
end