require "spec_helper"
require "graphql/compatibility"
SerialExecutionSuite = GraphQL::Compatibility::ExecutionSpec.build_suite(GraphQL::Query::SerialExecution)
