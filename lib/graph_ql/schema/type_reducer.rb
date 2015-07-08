class GraphQL::Schema::TypeReducer
  FIELDS_TYPE_KINDS = [GraphQL::TypeKinds::OBJECT]
  attr_reader :type, :result
  def initialize(type, existing_type_hash)
    if existing_type_hash.has_key?(type.name)
      # been here, done that
      @result = existing_type_hash
    else
      @result = find_types(type, existing_type_hash.dup)
    end
  end

  private

  def find_types(type, type_hash)
    type_hash[type.name] = type
    if FIELDS_TYPE_KINDS.include?(type.kind)
      type.fields.each do |name, field|
        reducer = self.class.new(field.type, type_hash)
        type_hash.merge!(reducer.result)
      end
    end
    type_hash
  end
end
