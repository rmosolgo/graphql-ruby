# Validates a schema (specifically, {GraphQL::SCHEMA}).
#
# It checks:
# - All classes exposed by nodes actually exist
# - Field types requested by nodes actually exist
# - Fields' corresponding methods actually exist
#
# To validate a schema, use {GraphQL::Schema::Schema#validate}.
class GraphQL::Schema::SchemaValidation
  # Validates the schema
  def validate(schema)
    schema.types.each do |type_name, type_class|

      if type_class.exposes_class_name.present?
        ensure_exposes_class_exists(type_class)
      end

      type_class.all_fields.each do |field_name, field_mapping|
        # Make sure it's in the schema:
        schema.get_field(field_mapping.type)

        # Make sure the node can handle it
        if !type_class.respond_to_field?(field_mapping.name)
          raise GraphQL::FieldNotDefinedError.new(type_class, field_mapping.name)
        end
      end
    end
  end

  private

  def ensure_exposes_class_exists(type_class)
    Object.const_get(type_class.exposes_class_name)
  rescue NameError
    raise GraphQL::ExposesClassMissingError.new(type_class)
  end
end