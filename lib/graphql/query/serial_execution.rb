module GraphQL
  class Query
    class SerialExecution < GraphQL::Query::BaseExecution
    end
  end
end

require 'graphql/query/serial_execution/field_resolution'
require 'graphql/query/serial_execution/fragment_spread_resolution'
require 'graphql/query/serial_execution/inline_fragment_resolution'
require 'graphql/query/serial_execution/operation_resolution'
require 'graphql/query/serial_execution/selection_resolution'
