module GraphQL
  # The parent type for scalars, eg {GraphQL::STRING_TYPE}, {GraphQL::INT_TYPE}
  #
  class ScalarType < GraphQL::ObjectType
    defined_by_config :name, :coerce
    attr_accessor :name

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
