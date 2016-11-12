require "spec_helper"

ExecuteSuite = GraphQL::Compatibility::ExecutionSpecification.build_suite(GraphQL::Execution::Execute)
LazyExecuteSuite = GraphQL::Compatibility::LazyExecutionSpecification.build_suite(GraphQL::Execution::Execute)
