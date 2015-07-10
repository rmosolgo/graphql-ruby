class GraphQL::Schema::TypeReducer
  FIELDS_TYPE_KINDS = [GraphQL::TypeKinds::OBJECT, GraphQL::TypeKinds::INTERFACE]
  POSSIBLE_TYPES_TYPE_KINDS = [GraphQL::TypeKinds::INTERFACE, GraphQL::TypeKinds::UNION]
  attr_reader :type, :result
  def initialize(type, existing_type_hash)
    if [GraphQL::TypeKinds::NON_NULL, GraphQL::TypeKinds::LIST].include?(type.kind)
      type = type.of_type
    end
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
        field.arguments.each do |name, argument|
          reducer = self.class.new(argument[:type], type_hash)
          type_hash.merge!(reducer.result)
        end
      end
    end
    if type.kind == GraphQL::TypeKinds::OBJECT
      type.interfaces.each do |interface|
        reducer = self.class.new(interface, type_hash)
        type_hash.merge!(reducer.result)
      end
    end
    if POSSIBLE_TYPES_TYPE_KINDS.include?(type.kind)
      type.possible_types.each do |possible_type|
        reducer = self.class.new(possible_type, type_hash)
        type_hash.merge!(reducer.result)
      end
    end
    type_hash
  end
end
