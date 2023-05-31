# frozen_string_literal: true
module GraphQL
  # Type kinds are the basic categories which a type may belong to (`Object`, `Scalar`, `Union`...)
  module TypeKinds
    # These objects are singletons, eg `GraphQL::TypeKinds::UNION`, `GraphQL::TypeKinds::SCALAR`.
    class TypeKind
      attr_reader :name, :description
      def initialize(name, abstract: false, leaf: false, fields: false, wraps: false, input: false, description: nil)
        @name = name
        @abstract = abstract
        @fields = fields
        @wraps = wraps
        @input = input
        @leaf = leaf
        @composite = fields? || abstract?
        @description = description
      end

      # Is this TypeKind abstract?
      attr_reader :abstract
      alias_method :abstract?, :abstract
      remove_method :abstract

      # Does this TypeKind have multiple possible implementers?
      # @deprecated Use `abstract?` instead of `resolves?`.
      alias_method :resolves?, :abstract?

      # Does this TypeKind have queryable fields?
      attr_reader :fields
      alias_method :fields?, :fields
      remove_method :fields

      # Does this TypeKind modify another type?
      attr_reader :wraps
      alias_method :wraps?, :wraps
      remove_method :wraps

      # Is this TypeKind a valid query input?
      attr_reader :input
      alias_method :input?, :input
      remove_method :input

      # Is this TypeKind a primitive value?
      attr_reader :leaf
      alias_method :leaf?, :leaf
      remove_method :leaf

      # Is this TypeKind composed of many values?
      attr_reader :composite
      alias_method :composite?, :composite
      remove_method :composite

      alias_method :to_s, :name

      def scalar?
        self == TypeKinds::SCALAR
      end

      def object?
        self == TypeKinds::OBJECT
      end

      def interface?
        self == TypeKinds::INTERFACE
      end

      def union?
        self == TypeKinds::UNION
      end

      def enum?
        self == TypeKinds::ENUM
      end

      def input_object?
        self == TypeKinds::INPUT_OBJECT
      end

      def list?
        self == TypeKinds::LIST
      end

      def non_null?
        self == TypeKinds::NON_NULL
      end
    end

    TYPE_KINDS = [
      SCALAR =        TypeKind.new("SCALAR", input: true, leaf: true, description: 'Indicates this type is a scalar.'),
      OBJECT =        TypeKind.new("OBJECT", fields: true, description: 'Indicates this type is an object. `fields` and `interfaces` are valid fields.'),
      INTERFACE =     TypeKind.new("INTERFACE", abstract: true, fields: true, description: 'Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.'),
      UNION =         TypeKind.new("UNION", abstract: true, description: 'Indicates this type is a union. `possibleTypes` is a valid field.'),
      ENUM =          TypeKind.new("ENUM", input: true, leaf: true, description: 'Indicates this type is an enum. `enumValues` is a valid field.'),
      INPUT_OBJECT =  TypeKind.new("INPUT_OBJECT", input: true, description: 'Indicates this type is an input object. `inputFields` is a valid field.'),
      LIST =          TypeKind.new("LIST", wraps: true, description: 'Indicates this type is a list. `ofType` is a valid field.'),
      NON_NULL =      TypeKind.new("NON_NULL", wraps: true, description: 'Indicates this type is a non-null. `ofType` is a valid field.'),
    ]
  end
end
