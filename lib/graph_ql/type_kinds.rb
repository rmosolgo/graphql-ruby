module GraphQL::TypeKinds
  class TypeKind
    attr_reader :name
    def initialize(name, resolves: false, fields: false, wraps: false, input: false)
      @name = name
      @resolves = resolves
      @fields = fields
      @wraps = wraps
      @input = input
      @composite = fields? || resolves?
    end

    def resolves?;  @resolves;  end
    def fields?;    @fields;    end
    def wraps?;     @wraps;     end
    def input?;     @input;     end
    def to_s;       @name;      end
    def composite?; @composite; end

    def resolve(type, value)
      if resolves?
        type.resolve_type(value)
      else
        type
      end
    end

    def unwrap(type)
      if wraps?
        wrapped_type = type.of_type
        wrapped_type.kind.unwrap(wrapped_type)
      else
        type
      end
    end
  end

  TYPE_KINDS = [
    SCALAR =        TypeKind.new("SCALAR", input: true),
    OBJECT =        TypeKind.new("OBJECT", fields: true),
    INTERFACE =     TypeKind.new("INTERFACE", resolves: true, fields: true),
    UNION =         TypeKind.new("UNION", resolves: true),
    ENUM =          TypeKind.new("ENUM", input: true),
    INPUT_OBJECT =  TypeKind.new("INPUT_OBJECT", input: true),
    LIST =          TypeKind.new("LIST", wraps: true),
    NON_NULL =      TypeKind.new("NON_NULL", wraps: true),
  ]

  KIND_NAMES = TYPE_KINDS.map(&:name)
  class TypeKind
    KIND_NAMES.each do |kind_name|
      define_method("#{kind_name.downcase}?") do
        self.name == kind_name
      end
    end
  end
end
