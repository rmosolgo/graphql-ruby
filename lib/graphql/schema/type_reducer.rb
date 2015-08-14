# Starting from a given type, discover other types in the system by
# traversing that type's fields, possible_types, etc
class GraphQL::Schema::TypeReducer
  attr_reader :type, :existing_type_hash

  def initialize(type, existing_type_hash)
    @type = type
    @existing_type_hash = existing_type_hash
  end

  def result
    @result ||= if type.respond_to?(:kind) && type.kind.wraps?
      reduce_type(type.of_type, existing_type_hash)
    elsif type.respond_to?(:name) && existing_type_hash.has_key?(type.name)
      # been here, done that
      existing_type_hash
    else
      validate_type(type)
      find_types(type, existing_type_hash.dup)
    end
  end

  # Reduce all of `types` and return the combined result
  def self.find_all(types)
    types.reduce({}) do |memo, type|
      self.new(type, memo).result
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

  def validate_type(type)
    errors = []
    type_validator = GraphQL::Schema::TypeValidator.new
    type_validator.validate(type, errors)
    if errors.any?
      raise GraphQL::Schema::InvalidTypeError.new(type, errors)
    end
  end
end
