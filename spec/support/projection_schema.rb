# Project an incrementing integer
# Then resolve to display that integer
def create_int_projection_field
  GraphQL::Field.define do
    type(!types.Int)
    description("Project the next integer")
    project -> (type, args, ctx)  { ctx[:counter] += 1 }
  end
end

def fetch_projected_value(projections, field_name)
  projections[field_name] ? projections[field_name][:projections] : nil
end

ProjectorField = GraphQL::Field.define do
  type(-> { ProjectableInterface })
  description("Return a Projector")
  resolve -> (object, arg, ctx) {
    projections = ctx.projections["Projector"]
    values = {
      projectedInt: fetch_projected_value(projections, "projectedInt"),
      projectedInt2: fetch_projected_value(projections, "projectedInt2"),
      resolvedInt: ctx[:counter] += 1,
    }
    OpenStruct.new(values)
  }
end

ProjectableInterface = GraphQL::InterfaceType.define do
  name "Projectable"
  field :projectedInt, types.Int
  field :projectedInt2, types.Int
  field :resolvedInt, types.Int
  field :projector, -> { ProjectableInterface }
  resolve_type -> (obj) {
    ProjectorType
  }
end

BogusType = GraphQL::ObjectType.define do
  name("Bogus")
  field :projectedInt, types.Int do
    resolve -> (obj, args, ctx) { raise("Don't call this") }
  end
  field :projectedInt2, types.Int do
    resolve -> (obj, args, ctx) { raise("Don't call this") }
  end
  field :resolvedInt, types.Int do
    resolve -> (obj, args, ctx) { raise("Don't call this") }
  end
  field :projector, field: ProjectorField
  interfaces([ProjectableInterface])
end

ProjectorType = GraphQL::ObjectType.define do
  name("Projector")
  field :projectedInt, field: create_int_projection_field
  field :projectedInt2, field: create_int_projection_field
  field :resolvedInt, !types.Int
  field :projector, field: ProjectorField
  interfaces([ProjectableInterface])
end



ProjectorQueryType = GraphQL::ObjectType.define do
  name "ProjectorQuery"
  field :projector, field: ProjectorField
end

ProjectorSchema = GraphQL::Schema.new(query: ProjectorQueryType)
