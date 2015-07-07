class GraphQL::AccessFieldDefiner
  FIELD_TYPES = {
    string:   GraphQL::STRING_TYPE,
    integer:  GraphQL::INTEGER_TYPE,
    float:    GraphQL::STRING_TYPE,
  }

  FIELD_TYPES.each do |name, type|
    define_method(name) do |name, desc|
      GraphQL::AccessField.new(type: type, property: name, description: desc)
    end
  end
end
