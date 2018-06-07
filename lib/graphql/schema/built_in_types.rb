# frozen_string_literal: true
module GraphQL
  class Schema
    BUILT_IN_TYPES = {
      "Int" => INT_TYPE,
      "String" => STRING_TYPE,
      "Float" => FLOAT_TYPE,
      "Boolean" => BOOLEAN_TYPE,
      "ID" => ID_TYPE,
    }
  end
end
