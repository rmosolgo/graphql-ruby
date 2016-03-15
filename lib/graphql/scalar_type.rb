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
      @coerce_input_proc.call(value)
    end

    def coerce_input=(proc)
      if !proc.nil?
        @coerce_input_proc = proc
      end
    end

    def coerce_result(value)
      @coerce_result_proc.call(value)
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
