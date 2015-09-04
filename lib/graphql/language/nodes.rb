module GraphQL::Language::Nodes
  # AbstractNode creates classes who:
  # - require their keyword arguments, throw ArgumentError if they don't match
  # - expose accessors for keyword arguments
  class AbstractNode
    attr_accessor :line, :col

    # @param options [Hash] Must contain all attributes defined by {required_attrs}, may also include `position_source`
    def initialize(options)
      required_keys = self.class.required_attrs
      allowed_keys = required_keys + [:line, :col]
      position_source = options.delete(:position_source)
      if !position_source.nil?
        options[:line], options[:col] = position_source.line_and_column
      end

      present_keys = options.keys
      extra_keys = present_keys - allowed_keys
      if extra_keys.any?
        raise ArgumentError, "#{self.class.name} Extra arguments: #{extra_keys}"
      end

      missing_keys = required_keys - present_keys
      if missing_keys.any?
        raise ArgumentError, "#{self.class.name} Missing arguments: #{missing_keys}"
      end

      allowed_keys.each do |key|
        if options.has_key?(key)
          value = options[key]
          self.send("#{key}=", value)
        end
      end
    end

    # Test all attributes, checking for any other nodes below this one
    def children
      self.class.required_attrs
        .map { |attr| send(attr) }
        .flatten
        .select { |val| val.is_a?(GraphQL::Language::Nodes::AbstractNode) }
    end

    class << self
      attr_reader :required_attrs
      # Defines attributes which are required at initialization.
      def attr_required(*attr_names)
        @required_attrs ||= []
        @required_attrs += attr_names
        attr_accessor(*attr_names)
      end

      # Create a new AbstractNode child which
      # requires and exposes {attr_names}.
      # @param attr_names [Array<Symbol>] Attributes this node class will have
      # @param block [Block] Block passed to `Class.new`
      # @return [Class] A new node class
      def create(*attr_names, &block)
        cls = Class.new(self, &block)
        cls.attr_required(*attr_names)
        cls
      end
    end
  end

  Argument = AbstractNode.create(:name, :value)
  Directive = AbstractNode.create(:name, :arguments)
  Document = AbstractNode.create(:parts)
  Enum = AbstractNode.create(:name)
  Field = AbstractNode.create(:name, :alias, :arguments, :directives, :selections)
  FragmentDefinition = AbstractNode.create(:name, :type, :directives, :selections)
  FragmentSpread = AbstractNode.create(:name, :directives)
  InlineFragment = AbstractNode.create(:type, :directives, :selections)
  InputObject = AbstractNode.create(:pairs) do
    def to_h(options={})
      pairs.inject({}) do |memo, pair|
        v = pair.value
        memo[pair.name] = v.is_a?(InputObject) ? v.to_h : v
        memo
      end
    end
  end
  ListType = AbstractNode.create(:of_type)
  NonNullType = AbstractNode.create(:of_type)
  OperationDefinition = AbstractNode.create(:operation_type, :name, :variables, :directives, :selections)
  TypeName = AbstractNode.create(:name)
  Variable = AbstractNode.create(:name, :type, :default_value)
  VariableIdentifier = AbstractNode.create(:name)
end
