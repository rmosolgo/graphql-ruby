module StaticAnalysisHelpers
  def get_errors(query_string, schema:)
    query_ast = GraphQL.parse(query_string)
    visitor = GraphQL::Language::Visitor.new(query_ast)
    analysis = GraphQL::StaticAnalysis.prepare(visitor, schema: schema)
    visitor.visit
    analysis.errors
  end

  def assert_errors(query_string, *expected_error_messages, schema: AnalysisSchema)
    errors = get_errors(query_string, schema: schema)
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

    ADDITION =        -> (operands) { operands[:lhs] + operands[:rhs] }
    SUBTRACTION =     -> (operands) { operands[:lhs] - operands[:rhs] }
    MULTIPLICATION =  -> (operands) { operands[:lhs] * operands[:rhs] }
    DIVISION =        -> (operands) { operands[:lhs] / operands[:rhs] }
  end

  OperationInterface = GraphQL::InterfaceType.define do
    name "Operation"
    field :perform, CalculationResultUnion do
      argument :operands, !OperandsInput
      resolve -> (obj, args, ctx) {
        obj.call(args[:operands])
      }
    end
  end

  OperationNameEnum = GraphQL::EnumType.define do
    name "OperationName"
    value "ADDITION",       value: Calculation::ADDITION
    value "SUBTRACTION",    value: Calculation::SUBTRACTION
    value "MULTIPLICATION", value: Calculation::MULTIPLICATION
    value "DIVISION",       value: Calculation::DIVISION
  end

  CalculationSuccessType = GraphQL::ObjectType.define do
    name "CalculationSuccess"
    field :value, !types.Int
    field :calculate, !CalculationResultUnion do
      argument :expression, !ExpressionInput
      resolve(Calculation)
    end
  end

  CalculationErrorType = GraphQL::ObjectType.define do
    name "CalculationError"
    field :message, !types.String
  end

  CalculationResultUnion = GraphQL::UnionType.define do
    name "CalculationResult"
    possible_types [
      CalculationSuccessType,
      CalculationErrorType,
    ]
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
    field :addInt, CalculationSuccessType do
      argument :lhs, !types.Int
      argument :rhs, !types.Int
      resolve -> (o, a, c) { a[:lhs] + a[:rhs] }
    end

    field :calculate, CalculationResultUnion do
      argument :expression, !ExpressionInput
      resolve(Calculation)
    end

    field :operation, OperationInterface do
      argument :type, !OperationNameEnum
      resolve -> (obj, args, ctx) { args[:type] }
    end

    field :reduce, !types.Float do
      description "Reduce some integers to a float"
      argument :ints, !types[!types.Int]
      argument :operation, !OperationNameEnum
      resolve -> (o, a, c) {
        # todo: use the specified operation to reduce the array
      }
    end
  end

  AnalysisSchema = GraphQL::Schema.define do
    query QueryType
  end
end
