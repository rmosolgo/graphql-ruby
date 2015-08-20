# Project an incrementing integer
# Then resolve to display that integer
ProjectFromContextField = GraphQL::Field.define do
  type(!types.Int)
  description("Project the next integer")
  project -> (type, args, ctx)  { ctx[:counter] += 1 }
  resolve -> (obj, args, ctx) { GraphQL::Query::DEFAULT_RESOLVE }
end

ProjectorField = GraphQL::Field.define do
  type(-> { ProjectorType })
  description("Return a Projector")
  resolve -> (object, arg, ctx) {
    values = ctx.projections.merge({name: "Projector #{ctx[:counter]}", resolvedInt: ctx[:counter] += 1 })
    OpenStruct.new(values)
  }
end


ProjectorType = GraphQL::ObjectType.define do
  name("Projector")
  field :projectedInt, field: ProjectFromContextField
  field :projectedInt2, field: ProjectFromContextField
  field :resolvedInt, !types.Int
  field :projector, field: ProjectorField
  field :name, !types.String
end

ProjectorQueryType = GraphQL::ObjectType.define do
  field :projector, field: ProjectorField
end

ProjectorSchema = GraphQL::Schema.new(query: ProjectorQueryType)
