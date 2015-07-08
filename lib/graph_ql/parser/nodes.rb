module GraphQL::Nodes
  # AbstractNode creates classes who:
  # - require their keyword arguments, throw ArgumentError if they don't match
  # - expose accessors for keyword arguments
  class AbstractNode
    def initialize(options)
      required_keys = self.class.required_attrs

      extra_keys = options.keys - required_keys
      if extra_keys.any?
        raise ArgumentError, "#{self.class.name} Extra arguments: #{extra_keys}"
      end

      required_keys.each do |attr|
        if !options.has_key?(attr)
          raise ArgumentError, "#{self.class.name} Missing argument: #{attr}"
        else
          value = options[attr]
          self.send("#{attr}=", value)
        end
      end
    end

    def children
      self.class.required_attrs
        .map { |attr| send(attr) }
        .flatten # eg #fields is a list of children
        .select { |val| val.is_a?(GraphQL::Nodes::AbstractNode) }
    end

    class << self
      attr_reader :required_attrs
      def attr_required(*attr_names)
        @required_attrs ||= []
        @required_attrs += attr_names
        attr_accessor(*attr_names)
      end

      # Create a new AbstractNode child which
      # requires and exposes {attr_names}.
      def create(*attr_names, &block)
        cls = Class.new(self, &block)
        cls.attr_required(*attr_names)
        cls
      end
    end
  end

  Directive = AbstractNode.create(:name, :argument)
  Document = AbstractNode.create(:parts)
  Enum = AbstractNode.create(:name)
  Field = AbstractNode.create(:name, :alias, :arguments, :directives, :selections)
  FieldArgument = AbstractNode.create(:name, :value)
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
  InputObjectPair = AbstractNode.create(:name, :value)
  ListType = AbstractNode.create(:of_type)
  NonNullType = AbstractNode.create(:of_type)
  OperationDefinition = AbstractNode.create(:operation_type, :name, :variables, :directives, :selections)
  TypeName = AbstractNode.create(:name)
  Variable = AbstractNode.create(:name, :type, :default_value)
  VariableIdentifier = AbstractNode.create(:name)
end
