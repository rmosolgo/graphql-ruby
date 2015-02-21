class GraphQL::Types::TypeField < GraphQL::Types::ObjectField
  type "__type__"
  def finished_value
    GraphQL::SCHEMA.get_type(self.owner.class.schema_name)
  end
end