# Starting from a given type, discover other types in the system by
# traversing that type's fields, possible_types, etc
class GraphQL::Schema::TypeReducer
  attr_reader :type, :result
  def initialize(type, existing_type_hash)
    if [GraphQL::TypeKinds::NON_NULL, GraphQL::TypeKinds::LIST].include?(type.kind)
      @result = reduce_type(type.of_type, existing_type_hash)
    elsif existing_type_hash.has_key?(type.name)
      # been here, done that
      @result = existing_type_hash
    else
      @result = find_types(type, existing_type_hash.dup)
    end
  end

  private

  def find_types(type, type_hash)
    type_hash[type.name] = type
    if type.kind.fields?
      type.fields.each do |name, field|
        type_hash.merge!(reduce_type(field.type, type_hash))
        field.arguments.each do |name, argument|
          type_hash.merge!(reduce_type(argument.type, type_hash))
        end
      end
    end
    if type.kind.object?
      type.interfaces.each do |interface|
        type_hash.merge!(reduce_type(interface, type_hash))
      end
    end
    if type.kind.resolves?
      type.possible_types.each do |possible_type|
        type_hash.merge!(reduce_type(possible_type, type_hash))
      end
    end
    type_hash
  end

  def reduce_type(type, type_hash)
    self.class.new(type, type_hash).result
  end
end
