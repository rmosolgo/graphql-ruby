class GraphQL::Types::TimeType < GraphQL::Types::DateTimeType
  exposes "Time"
  type :time
  field.number(:usec)
end