class GraphQL::Types::DateTimeType < GraphQL::Types::DateType
  exposes "DateTime"
  type :date_time
  field.number(:hour)
  field.number(:min)
  field.number(:sec)
end