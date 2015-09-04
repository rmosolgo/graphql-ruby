# The introspection query to end all introspection queries, copied from
# https://github.com/graphql/graphql-js/blob/master/src/utilities/introspectionQuery.js
GraphQL::Introspection::INTROSPECTION_QUERY = "
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      args {
        ...InputValue
      }
      onOperation
      onFragment
      onField
    }
  }
}
fragment FullType on __Type {
  kind
  name
  description
  fields {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues {
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
      }
    }
  }
}
"
