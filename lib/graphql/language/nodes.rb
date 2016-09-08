module GraphQL
  module Language
    module Nodes
      # AbstractNode creates classes who:
      # - require their keyword arguments, throw ArgumentError if they don't match
      # - expose accessors for keyword arguments
      class AbstractNode
        attr_accessor :line, :col

        # @param options [Hash] Must contain all attributes defined by {required_attrs}, may also include `position_source`
        def initialize(options={})
          if options.key?(:position_source)
            position_source = options.delete(:position_source)
            @line, @col = position_source.line_and_column
          elsif options.key?(:line)
            @line = options.delete(:line)
            @col = options.delete(:col)
          end

          initialize_node(options)
        end

        # This is called with node-specific options
        def initialize_node(options={})
          raise NotImplementedError
        end

        def eql?(other)
          return true if equal?(other)
          other.is_a?(self.class) &&
            other.scalars.eql?(self.scalars) &&
            other.children.eql?(self.children)
        end

        # @return [GraphQL::Language::Nodes::AbstractNode] all nodes in the tree below this one
        def children
          self.class.child_attributes
            .map { |attr_name| public_send(attr_name) }
            .flatten
        end

        def scalars
          self.class.scalar_attributes
            .map { |attr_name| public_send(attr_name) }
        end

        class << self
          def inherited(subclass)
            subclass.scalar_attributes(*@scalar_attributes)
            subclass.child_attributes(*@child_attributes)
          end

          def scalar_attributes(*attr_names)
            @scalar_attributes ||= []
            @scalar_attributes += attr_names
          end

          def child_attributes(*attr_names)
            @child_attributes ||= []
            @child_attributes += attr_names
          end
        end

        def position
          [line, col]
        end

        def to_query_string
          Generation.generate(self)
        end
      end

      class WrapperType < AbstractNode
        attr_accessor :of_type
        scalar_attributes :of_type

        def initialize_node(of_type: nil)
          @of_type = of_type
        end

        def children
          [].freeze
        end
      end

      class NameOnlyNode < AbstractNode
        attr_accessor :name
        scalar_attributes :name

        def initialize_node(name: nil)
          @name = name
        end

        def children
          [].freeze
        end
      end


      class Argument < AbstractNode
        attr_accessor :name, :value
        scalar_attributes :name, :value

        def initialize_node(name: nil, value: nil)
          @name = name
          @value = value
        end

        def children
          [value].flatten.select { |v| v.is_a?(AbstractNode) }
        end
      end

      class Directive < AbstractNode
        attr_accessor :name, :arguments
        scalar_attributes :name
        child_attributes :arguments

        def initialize_node(name: nil, arguments: [])
          @name = name
          @arguments = arguments
        end
      end

      class Document < AbstractNode
        attr_accessor :definitions
        child_attributes :definitions

        def initialize_node(definitions: [])
          @definitions = definitions
        end
      end

      class Enum < NameOnlyNode; end

      class Field < AbstractNode
        attr_accessor :name, :alias, :arguments, :directives, :selections
        scalar_attributes :name, :alias
        child_attributes :arguments, :directives, :selections

        def initialize_node(name: nil, arguments: [], directives: [], selections: [], **kwargs)
          @name = name
          # oops, alias is a keyword:
          @alias = kwargs.fetch(:alias, nil)
          @arguments = arguments
          @directives = directives
          @selections = selections
        end
      end

      class FragmentDefinition < AbstractNode
        attr_accessor :name, :type, :directives, :selections
        scalar_attributes :name, :type
        child_attributes :directives, :selections

        def initialize_node(name: nil, type: nil, directives: [], selections: [])
          @name = name
          @type = type
          @directives = directives
          @selections = selections
        end
      end

      class FragmentSpread < AbstractNode
        attr_accessor :name, :directives
        scalar_attributes :name
        child_attributes :directives

        def initialize_node(name: nil, directives: [])
          @name = name
          @directives = directives
        end
      end

      class InlineFragment < AbstractNode
        attr_accessor :type, :directives, :selections
        scalar_attributes :type
        child_attributes :directives, :selections

        def initialize_node(type: nil, directives: [], selections: [])
          @type = type
          @directives = directives
          @selections = selections
        end
      end

      class InputObject < AbstractNode
        attr_accessor :arguments
        child_attributes :arguments

        def initialize_node(arguments: [])
          @arguments = arguments
        end

        def to_h(options={})
          arguments.inject({}) do |memo, pair|
            v = pair.value
            memo[pair.name] = v.is_a?(InputObject) ? v.to_h : v
            memo
          end
        end
      end



      class ListType < WrapperType; end
      class NonNullType < WrapperType; end

      class OperationDefinition < AbstractNode
        attr_accessor :operation_type, :name, :variables, :directives, :selections
        scalar_attributes :operation_type, :name
        child_attributes :variables, :directives, :selections

        def initialize_node(operation_type: nil, name: nil, variables: [], directives: [], selections: [])
          @operation_type = operation_type
          @name = name
          @variables = variables
          @directives = directives
          @selections = selections
        end
      end

      class TypeName < NameOnlyNode; end

      class VariableDefinition < AbstractNode
        attr_accessor :name, :type, :default_value
        scalar_attributes :name, :type, :default_value

        def initialize_node(name: nil, type: nil, default_value: nil)
          @name = name
          @type = type
          @default_value = default_value
        end
      end

      class VariableIdentifier < NameOnlyNode; end


      class SchemaDefinition < AbstractNode
        attr_accessor :query, :mutation, :subscription
        scalar_attributes :query, :mutation, :subscription

        def initialize_node(query: nil, mutation: nil, subscription: nil)
          @query = query
          @mutation = mutation
          @subscription = subscription
        end
      end

      class ScalarTypeDefinition < NameOnlyNode; end

      class ObjectTypeDefinition < AbstractNode
        attr_accessor :name, :interfaces, :fields
        scalar_attributes :name
        child_attributes :interfaces, :fields

        def initialize_node(name:, interfaces:, fields:)
          @name = name
          @interfaces = interfaces || []
          @fields = fields
        end
      end

      class InputValueDefinition < AbstractNode
        attr_accessor :name, :type, :default_value
        scalar_attributes :name, :type, :default_value

        def initialize_node(name:, type:, default_value: nil)
          @name = name
          @type = type
          @default_value = default_value
        end
      end

      class FieldDefinition < AbstractNode
        attr_accessor :name, :arguments, :type
        scalar_attributes :name, :type
        child_attributes :arguments

        def initialize_node(name:, arguments:, type:)
          @name = name
          @arguments = arguments
          @type = type
        end
      end

      class InterfaceTypeDefinition < AbstractNode
        attr_accessor :name, :fields
        scalar_attributes :name
        child_attributes :fields

        def initialize_node(name:, fields:)
          @name = name
          @fields = fields
        end
      end

      class UnionTypeDefinition < AbstractNode
        attr_accessor :name, :types
        scalar_attributes :name
        child_attributes :types

        def initialize_node(name:, types:)
          @name = name
          @types = types
        end
      end

      class EnumTypeDefinition < AbstractNode
        attr_accessor :name, :values
        scalar_attributes :name
        child_attributes :values

        def initialize_node(name:, values:)
          @name = name
          @values = values
        end
      end

      class InputObjectTypeDefinition < AbstractNode
        attr_accessor :name, :fields
        scalar_attributes :name
        child_attributes :fields

        def initialize_node(name:, fields:)
          @name = name
          @fields = fields
        end
      end
    end
  end
end
