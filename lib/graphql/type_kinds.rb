module GraphQL
  # Type kinds are the basic categories which a type may belong to (`Object`, `Scalar`, `Union`...)
  module TypeKinds
    # These objects are singletons, eg `GraphQL::TypeKinds::UNION`, `GraphQL::TypeKinds::SCALAR`.
    class TypeKind
      attr_reader :name, :description
      ### Ruby 1.9.3 unofficial support
      # def initialize(name, resolves: false, fields: false, wraps: false, input: false, description: nil)
      def initialize(name, options = {})
        resolves = options.fetch(:resolves, false)
        fields = options.fetch(:fields, false)
        wraps = options.fetch(:wraps, false)
        input = options.fetch(:input, false)
        description = options.fetch(:description, nil)

        @name = name
        @resolves = resolves
        @fields = fields
        @wraps = wraps
        @input = input
        @composite = fields? || resolves?
        @description = description
      end

      # Does this TypeKind have multiple possible implementors?
      def resolves?;  @resolves;  end
      # Does this TypeKind have queryable fields?
      def fields?;    @fields;    end
      # Does this TypeKind modify another type?
      def wraps?;     @wraps;     end
      # Is this TypeKind a valid query input?
      def input?;     @input;     end
      def to_s;       @name;      end
      # Is this TypeKind composed of many values?
      def composite?; @composite; end
    end

    TYPE_KINDS = [
      SCALAR =        TypeKind.new("SCALAR", input: true, description: 'Indicates this type is a scalar.'),
      OBJECT =        TypeKind.new("OBJECT", fields: true, description: 'Indicates this type is an object. `fields` and `interfaces` are valid fields.'),
      INTERFACE =     TypeKind.new("INTERFACE", resolves: true, fields: true, description: 'Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.'),
      UNION =         TypeKind.new("UNION", resolves: true, description: 'Indicates this type is a union. `possibleTypes` is a valid field.'),
      ENUM =          TypeKind.new("ENUM", input: true, description: 'Indicates this type is an enum. `enumValues` is a valid field.'),
      INPUT_OBJECT =  TypeKind.new("INPUT_OBJECT", input: true, description: 'Indicates this type is an input object. `inputFields` is a valid field.'),
      LIST =          TypeKind.new("LIST", wraps: true, description: 'Indicates this type is a list. `ofType` is a valid field.'),
      NON_NULL =      TypeKind.new("NON_NULL", wraps: true, description: 'Indicates this type is a non-null. `ofType` is a valid field.'),
    ]

    class TypeKind
      TYPE_KINDS.map(&:name).each do |kind_name|
        define_method("#{kind_name.downcase}?") do
          self.name == kind_name
        end
      end
    end
  end
end
