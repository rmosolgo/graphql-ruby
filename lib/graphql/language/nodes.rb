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

        # @return [GraphQL::Language::Nodes::AbstractNode] all nodes in the tree below this one
        def children
          self.class.child_attributes
            .map { |attr_name| public_send(attr_name) }
            .flatten
        end

        class << self
          def child_attributes(*attr_names)
            @child_attributes ||= []
            @child_attributes += attr_names
          end
        end

        def position
          [line, col]
        end

        private

        def generate_value(value)
          case value
          when AbstractNode
            value.to_query_string
          when FalseClass, Float, Integer, NilClass, String, TrueClass
            JSON.generate(value, quirks_mode: true)
          when Array
            "[#{value.map { |v| generate_value(v) }.join(", ")}]"
          when Hash
            "{#{value.map { |k, v| "#{k}: #{generate_value(v)}" }.join(", ")}}"
          else
            raise TypeError
          end
        end

        def generate_directives(directives)
          if directives.any?
            directives.map { |d| " #{d.to_query_string}" }.join
          else
            ""
          end
        end

        def generate_selections(selections, indent: "")
          if selections.any?
            out = " {\n"
            selections.each do |selection|
              out << selection.to_query_string(indent: indent + "  ") << "\n"
            end
            out << "#{indent}}"
          else
            ""
          end
        end
      end

      class WrapperType < AbstractNode
        attr_accessor :of_type
        def initialize_node(of_type: nil)
          @of_type = of_type
        end

        def children
          [].freeze
        end
      end

      class NameOnlyNode < AbstractNode
        attr_accessor :name
        def initialize_node(name: nil)
          @name = name
        end

        def children
          [].freeze
        end
      end


      class Argument < AbstractNode
        attr_accessor :name, :value

        def initialize_node(name: nil, value: nil)
          @name = name
          @value = value
        end

        def children
          [value].flatten.select { |v| v.is_a?(AbstractNode) }
        end

        def to_query_string
          "#{name}: #{generate_value(value)}"
        end
      end

      class Directive < AbstractNode
        attr_accessor :name, :arguments
        child_attributes :arguments

        def initialize_node(name: nil, arguments: [])
          @name = name
          @arguments = arguments
        end

        def to_query_string
          "@#{name}(#{arguments.map(&:to_query_string).join(", ")})"
        end
      end

      class Document < AbstractNode
        attr_accessor :definitions
        child_attributes :definitions

        def initialize_node(definitions: [])
          @definitions = definitions
        end

        def to_query_string
          definitions.map(&:to_query_string).join("\n")
        end
      end

      class Enum < NameOnlyNode
        def to_query_string
          "#{name}"
        end
      end

      class Field < AbstractNode
        attr_accessor :name, :alias, :arguments, :directives, :selections
        child_attributes :arguments, :directives, :selections

        def initialize_node(name: nil, arguments: [], directives: [], selections: [], **kwargs)
          @name = name
          # oops, alias is a keyword:
          @alias = kwargs.fetch(:alias, nil)
          @arguments = arguments
          @directives = directives
          @selections = selections
        end

        def to_query_string(indent: "")
          out = "#{indent}"
          out << "#{self.alias}: " if self.alias
          out << "#{name}"
          out << "(#{arguments.map(&:to_query_string).join(", ")})" if arguments.any?
          out << generate_directives(directives)
          out << generate_selections(selections, indent: indent)
          out
        end
      end

      class FragmentDefinition < AbstractNode
        attr_accessor :name, :type, :directives, :selections
        child_attributes :directives, :selections

        def initialize_node(name: nil, type: nil, directives: [], selections: [])
          @name = name
          @type = type
          @directives = directives
          @selections = selections
        end

        def to_query_string(indent: "")
          out = "#{indent}fragment #{name}"
          out << " on #{type}" if type
          out << generate_directives(directives)
          out << generate_selections(selections, indent: indent)
          out
        end
      end

      class FragmentSpread < AbstractNode
        attr_accessor :name, :directives
        child_attributes :directives

        def initialize_node(name: nil, directives: [])
          @name = name
          @directives = directives
        end

        def to_query_string(indent: "")
          out = "#{indent}... #{name}"
          out << generate_directives(directives)
          out
        end
      end

      class InlineFragment < AbstractNode
        attr_accessor :type, :directives, :selections
        child_attributes :directives, :selections

        def initialize_node(type: nil, directives: [], selections: [])
          @type = type
          @directives = directives
          @selections = selections
        end

        def to_query_string(indent: "")
          out = "#{indent}..."
          out << " on #{type}" if type
          out << generate_directives(directives)
          out << generate_selections(selections, indent: indent)
          out
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

        def to_query_string
          generate_value(to_h)
        end
      end

      class ListType < WrapperType
        def to_query_string
          "[#{of_type.to_query_string}]"
        end
      end

      class NonNullType < WrapperType
        def to_query_string
          "#{of_type.to_query_string}!"
        end
      end

      class OperationDefinition < AbstractNode
        attr_accessor :operation_type, :name, :variables, :directives, :selections
        child_attributes :variables, :directives, :selections

        def initialize_node(operation_type: nil, name: nil, variables: [], directives: [], selections: [])
          @operation_type = operation_type
          @name = name
          @variables = variables
          @directives = directives
          @selections = selections
        end

        def to_query_string(indent: "")
          out = "#{indent}#{operation_type} #{name}"
          out << "(#{variables.map(&:to_query_string).join(", ")})" if variables.any?
          out << generate_directives(directives)
          out << generate_selections(selections, indent: indent)
          out
        end
      end

      class TypeName < NameOnlyNode
        def to_query_string
          "#{name}"
        end
      end

      class VariableDefinition < AbstractNode
        attr_accessor :name, :type, :default_value
        def initialize_node(name: nil, type: nil, default_value: nil)
          @name = name
          @type = type
          @default_value = default_value
        end

        def to_query_string
          out = "$#{name}: #{type.to_query_string}"
          out << " = #{generate_value(default_value)}" if default_value
          out
        end
      end

      class VariableIdentifier < NameOnlyNode
        def to_query_string
          "$#{name}"
        end
      end
    end
  end
end
