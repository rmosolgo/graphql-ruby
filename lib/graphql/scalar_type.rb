module GraphQL
  # The parent type for scalars, eg {GraphQL::STRING_TYPE}, {GraphQL::INT_TYPE}
  #
  # @example defining a type for Time
  #   TimeType = GraphQL::ObjectType.define do
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

    def coerce_input(value)
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
