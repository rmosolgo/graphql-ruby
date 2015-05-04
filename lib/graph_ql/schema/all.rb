# This query string yields the whole schema. Access it from {GraphQL::Schema::Schema#all}
GraphQL::Schema::ALL = "
schema() {
      calls {
        count,
        edges {
          node {
            name,
            returns,
            arguments {
              edges {
                node {
                  name, type
                }
              }
            }
          }
        }
      },
      types {
        count,
        edges {
          node {
            name,
            fields {
              count,
              edges {
                node {
                  name,
                  type,
                  calls {
                    count,
                    edges {
                      node {
                        name,
                        arguments
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }"