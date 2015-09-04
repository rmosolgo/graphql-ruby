module GraphQL
  # The parent type for scalars, eg {GraphQL::STRING_TYPE}, {GraphQL::INT_TYPE}
  #
  class ScalarType < GraphQL::BaseType
    defined_by_config :name, :coerce, :description
    attr_accessor :name, :description

    def coerce(value)
      @coerce_proc.call(value)
    end

    def coerce=(proc)
      @coerce_proc = proc
    end

    def kind
      GraphQL::TypeKinds::SCALAR
    end
  end
end
