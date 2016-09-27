module GraphQL
  # # GraphQL::ScalarType
  #
  # Scalars are plain values. They are leaf nodes in a GraphQL query tree.
  #
  # ## Built-in Scalars
  #
  # `GraphQL` comes with standard built-in scalars:
  #
  # |Constant | `.define` helper|
  # |-------|--------|
  # |`GraphQL::STRING_TYPE` | `types.String`|
  # |`GraphQL::INT_TYPE` | `types.Int`|
  # |`GraphQL::FLOAT_TYPE` | `types.Float`|
  # |`GraphQL::ID_TYPE` | `types.ID`|
  # |`GraphQL::BOOLEAN_TYPE` | `types.Boolean`|
  #
  # (`types` is an instance of `GraphQL::Definition::TypeDefiner`; `.String`, `.Float`, etc are methods which return built-in scalars.)
  #
  # ## Custom Scalars
  #
  # You can define custom scalars for your GraphQL server. It requires some special functions:
  #
  # - `coerce_input` is used to prepare incoming values for GraphQL execution. (Incoming values come from variables or literal values in the query string.)
  # - `coerce_result` is used to turn Ruby values _back_ into serializable values for query responses.
  #
  # @example defining a type for Time
  #   TimeType = GraphQL::ScalarType.define do
  #     name "Time"
  #     description "Time since epoch in seconds"
  #
  #     coerce_input ->(value) { Time.at(Float(value)) }
  #     coerce_result ->(value) { value.to_f }
  #   end
  #
  class ScalarType < GraphQL::BaseType
    accepts_definitions :coerce, :coerce_input, :coerce_result

    def coerce=(proc)
      self.coerce_input = proc
      self.coerce_result = proc
    end

    def validate_non_null_input(value)
      result = Query::InputValidationResult.new
      if coerce_non_null_input(value).nil?
        result.add_problem("Could not coerce value #{JSON.dump(value)} to #{name}")
      end
      result
    end

    def coerce_non_null_input(value)
      ensure_defined
      @coerce_input_proc.call(value)
    end

    def coerce_input=(proc)
      if !proc.nil?
        @coerce_input_proc = proc
      end
    end

    def coerce_result(value)
      ensure_defined
      @coerce_result_proc ? @coerce_result_proc.call(value) : value
    end

    def coerce_result=(proc)
      if !proc.nil?
        @coerce_result_proc = proc
      end
    end

    def kind
      GraphQL::TypeKinds::SCALAR
    end
  end
end
