module StaticAnalysisHelpers
  def get_errors(query_string, schema: AnalysisSchema)
    query_ast = GraphQL.parse(query_string)
    visitor = GraphQL::Language::Visitor.new(query_ast)
    analysis = GraphQL::StaticAnalysis.prepare(visitor, schema: schema)
    visitor.visit
    analysis.errors
  end

  def assert_errors(query_string, *expected_error_messages)
    errors = get_errors(query_string)
    messages = errors.map(&:message)
    expected_error_messages.each do |expected_message|
      assert_includes(messages, expected_message)
    end
    assert_equal(expected_error_messages.sort, messages.sort)
  end

  module Calculation
    def self.call(obj, args, ctx)
      # todo
    end
  end

  ResultType = GraphQL::ObjectType.define do
    name "Result"
    field :value, !types.Int
    field :calculate, !ResultType do
      argument :expression, !ExpressionInput
      resolve(Calculation)
    end
  end

  OperandsInput = GraphQL::InputObjectType.define do
    name "Operands"
    argument :lhs, !types.Int
    argument :rhs, types.Int
  end

  ExpressionInput = GraphQL::InputObjectType.define do
    name "Expression"
    argument :add, OperandsInput
    argument :subtract, OperandsInput
    argument :multiply, OperandsInput
    argument :divide, OperandsInput
  end

  QueryType = GraphQL::ObjectType.define do
    name "Query"
    field :addInt, ResultType do
      argument :lhs, !types.Int
      argument :rhs, !types.Int
      resolve -> (o, a, c) { a[:lhs] + a[:rhs] }
    end

    field :calculate, ResultType do
      argument :expression, !ExpressionInput
      resolve(Calculation)
    end
  end

  AnalysisSchema = GraphQL::Schema.define do
    query QueryType
  end
end
