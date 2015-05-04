class GraphQL::Types::TimeType < GraphQL::Types::DateTimeType
  exposes "Time"
  desc("A date-time with milliseconds")
  type :time
  field.number(:usec)
end