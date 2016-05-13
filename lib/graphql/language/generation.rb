require "graphql/language/nodes"

module GraphQL
  module Language
    module Nodes
      class AbstractNode
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

      class Argument < AbstractNode
        def to_query_string
          "#{name}: #{generate_value(value)}"
        end
      end

      class Directive < AbstractNode
        def to_query_string
          "@#{name}(#{arguments.map(&:to_query_string).join(", ")})"
        end
      end

      class Document < AbstractNode
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
        def to_query_string(indent: "")
          out = "#{indent}fragment #{name}"
          out << " on #{type}" if type
          out << generate_directives(directives)
          out << generate_selections(selections, indent: indent)
          out
        end
      end

      class FragmentSpread < AbstractNode
        def to_query_string(indent: "")
          out = "#{indent}... #{name}"
          out << generate_directives(directives)
          out
        end
      end

      class InlineFragment < AbstractNode
        def to_query_string(indent: "")
          out = "#{indent}..."
          out << " on #{type}" if type
          out << generate_directives(directives)
          out << generate_selections(selections, indent: indent)
          out
        end
      end

      class InputObject < AbstractNode
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
        def to_query_string(indent: "")
          out = "#{indent}#{operation_type}"
          out << " #{name}" if name
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

    module Generation
      def self.generate(node)
        node.to_query_string
      end
    end
  end
end
