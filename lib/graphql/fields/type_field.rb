class GraphQL::Fields::TypeField < GraphQL::Fields::ObjectField
  type "__type__"
  def finished_value
    GraphQL::SCHEMA.get_type(self.owner.class.schema_name)
  end
end