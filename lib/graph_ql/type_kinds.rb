module GraphQL::TypeKinds
  class TypeKind
    attr_reader :name
    def initialize(name, resolves: false, fields: false, wraps: false)
      @name = name
      @resolves = resolves
      @fields = fields
      @wraps = wraps
    end

    def resolves?;  @resolves;  end
    def fields?;    @fields;    end
    def wraps?;     @wraps;     end
  end

  TYPE_KINDS = [
    SCALAR =        TypeKind.new("SCALAR"),
    OBJECT =        TypeKind.new("OBJECT", fields: true),
    INTERFACE =     TypeKind.new("INTERFACE", resolves: true, fields: true),
    UNION =         TypeKind.new("UNION", resolves: true),
    ENUM =          TypeKind.new("ENUM"),
    INPUT_OBJECT =  TypeKind.new("INPUT_OBJECT"),
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
