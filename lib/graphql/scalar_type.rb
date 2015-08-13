module GraphQL
  # The parent type for scalars, eg {GraphQL::STRING_TYPE}, {GraphQL::INT_TYPE}
  #
  class ScalarType < GraphQL::ObjectType
    class DefinitionConfig < GraphQL::ObjectType::DefinitionConfig
      attr_definable :coerce

      def type_class
        GraphQL::ScalarType
      end

      def to_instance
        scalar_type = super
        scalar_type.coerce_proc = coerce
        scalar_type
      end
    end

    def coerce(value)
      @coerce_proc.call(value)
    end

    def coerce_proc=(proc)
      @coerce_proc = proc
    end

    def kind
      GraphQL::TypeKinds::SCALAR
    end
  end
end
