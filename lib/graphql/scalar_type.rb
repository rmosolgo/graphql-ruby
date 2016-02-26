module GraphQL
  # The parent type for scalars, eg {GraphQL::STRING_TYPE}, {GraphQL::INT_TYPE}
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
    defined_by_config :name, :coerce, :coerce_input, :coerce_result, :description
    attr_accessor :name, :description

    def coerce=(proc)
      self.coerce_input = proc
      self.coerce_result = proc
    end

    def valid_non_null_input?(value)
      !coerce_non_null_input(value).nil?
    end

    def validate_non_null_input(value)
      result = Query::InputValidationResult.new

      unless valid_non_null_input?(value)
        result.add_problem("Could not coerce value #{JSON.dump(value)} to #{name}")
      end

      result
    end

    def coerce_non_null_input(value)
      @coerce_input_proc.call(value)
    end

    def coerce_input=(proc)
      @coerce_input_proc = proc unless proc.nil?
    end

    def coerce_result(value)
      @coerce_result_proc.call(value)
    end

    def coerce_result=(proc)
      @coerce_result_proc = proc unless proc.nil?
    end

    def kind
      GraphQL::TypeKinds::SCALAR
    end
  end
end
