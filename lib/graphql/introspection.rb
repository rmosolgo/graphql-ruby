# frozen_string_literal: true
module GraphQL
  module Introspection
    def self.query(include_deprecated_args: false)
      # The introspection query to end all introspection queries, copied from
      # https://github.com/graphql/graphql-js/blob/master/src/utilities/introspectionQuery.js
      <<-QUERY
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args#{include_deprecated_args ? '(includeDeprecated: true)' : ''} {
        ...InputValue
      }
    }
  }
}
fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args#{include_deprecated_args ? '(includeDeprecated: true)' : ''} {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields#{include_deprecated_args ? '(includeDeprecated: true)' : ''} {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}
fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
  #{include_deprecated_args ? 'isDeprecated' : ''}
  #{include_deprecated_args ? 'deprecationReason' : ''}
}
fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
      QUERY
    end
  end
end

require "graphql/introspection/base_object"
require "graphql/introspection/input_value_type"
require "graphql/introspection/enum_value_type"
require "graphql/introspection/type_kind_enum"
require "graphql/introspection/type_type"
require "graphql/introspection/field_type"
require "graphql/introspection/directive_location_enum"
require "graphql/introspection/directive_type"
require "graphql/introspection/schema_type"
require "graphql/introspection/introspection_query"
require "graphql/introspection/dynamic_fields"
require "graphql/introspection/entry_points"
