class GraphQL::Types::TypeField < GraphQL::Types::ObjectField
  field_type "type"
  def finished_value
    GraphQL::SCHEMA.get_type(self.owner.class.schema_name)
  end
end