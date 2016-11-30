# frozen_string_literal: true
require "spec_helper"

SerialExecutionSuite = GraphQL::Compatibility::ExecutionSpecification.build_suite(GraphQL::Query::SerialExecution)
