module GraphQL
  module Language

    # {Transform} is a [parslet](http://kschiess.github.io/parslet/) transform for for turning the AST into objects in {GraphQL::Language::Nodes} objects.
    class Transform < Parslet::Transform

      # @param [Symbol] name of a node constant
      # @param [Hash] attributes to initialize the {Node} with
      # @return [GraphQL::Language::Node] a node of type `name` with attributes `attributes`
      CREATE_NODE = Proc.new do |name, attributes|
        node_class = GraphQL::Language::Nodes.const_get(name)
        node_class.new(attributes)
      end

      def self.optional_sequence(name)
        rule(name => simple(:val)) { [] }
        rule(name => sequence(:val)) { val }
      end

      # Document
      rule(document_parts: sequence(:p)) { CREATE_NODE[:Document, parts: p, line: (p.first ? p.first.line : 1), col: (p.first ? p.first.col : 1)]}
      rule(document_parts: simple(:p)) { CREATE_NODE[:Document, parts: [], line: 1, col: 1]}

      # Fragment Definition
      rule(
        fragment_keyword: simple(:kw),
        fragment_name:  simple(:name),
        type_condition: simple(:type),
        directives:     sequence(:directives),
        selections:     sequence(:selections)
      ) { CREATE_NODE[:FragmentDefinition, name: name.to_s, type: type.to_s, directives: directives, selections: selections, position_source: kw]}

      rule(
        fragment_spread_keyword: simple(:kw),
        fragment_spread_name: simple(:n),
        directives:           sequence(:d)
      ) { CREATE_NODE[:FragmentSpread, name: n.to_s, directives: d, position_source: kw]}

      rule(
        fragment_spread_keyword: simple(:kw),
        inline_fragment_type: simple(:n),
        directives: sequence(:d),
        selections: sequence(:s),
      ) { CREATE_NODE[:InlineFragment, type: n.to_s, directives: d, selections: s, position_source: kw]}

      # Operation Definition
      rule(
        operation_type: simple(:ot),
        name:           simple(:n),
        variables:      sequence(:v),
        directives:     sequence(:d),
        selections:     sequence(:s),
      ) { CREATE_NODE[:OperationDefinition, operation_type: ot.to_s, name: n.to_s, variables: v, directives: d, selections: s, position_source: ot] }
      optional_sequence(:optional_variables)
      rule(variable_name: simple(:n), variable_type: simple(:t), variable_optional_default_value: simple(:v)) { CREATE_NODE.(:Variable, name: n.name, type: t, default_value: v, line: n.line, col: n.col)}
      rule(variable_name: simple(:n), variable_type: simple(:t), variable_optional_default_value: sequence(:v)) { CREATE_NODE.(:Variable, name: n.name, type: t, default_value: v, line: n.line, col: n.col)}
      rule(variable_default_value: simple(:v) ) { v }
      rule(variable_default_value: sequence(:v) ) { v }
      # Query short-hand
      rule(unnamed_selections: sequence(:s)) { CREATE_NODE[:OperationDefinition, selections: s, operation_type: "query", name: nil, variables: [], directives: [], line: s.first.line, col: s.first.col]}

      # Field
      rule(
        alias: simple(:a),
        field_name: simple(:name),
        field_arguments: sequence(:args),
        directives: sequence(:dir),
        selections: sequence(:sel)
      ) { CREATE_NODE[:Field, alias: a && a.to_s, name: name.to_s, arguments: args, directives: dir, selections: sel, position_source: [a, name].find { |part| !part.nil? }] }

      rule(alias_name: simple(:a)) { a }
      optional_sequence(:optional_field_arguments)
      rule(field_argument_name: simple(:n), field_argument_value: simple(:v)) { CREATE_NODE[:Argument, name: n.to_s, value: v, position_source: n]}
      rule(field_argument_name: simple(:n), field_argument_value: subtree(:v)) { CREATE_NODE[:Argument, name: n.to_s, value: v, position_source: n]}
      optional_sequence(:optional_selections)
      optional_sequence(:optional_directives)

      # Directive
      rule(directive_name: simple(:name), directive_arguments: sequence(:args)) { CREATE_NODE[:Directive, name: name.to_s, arguments: args, position_source: name ] }
      rule(directive_argument_name: simple(:n), directive_argument_value: simple(:v)) { CREATE_NODE[:Argument, name: n.to_s, value: v, position_source: n]}
      optional_sequence(:optional_directive_arguments)

      # Type Defs
      rule(type_name: simple(:n))     { CREATE_NODE[:TypeName, name: n.to_s, position_source: n] }
      rule(list_type: simple(:t))     { CREATE_NODE[:ListType, of_type: t, line: t.line, col: t.col] }
      rule(non_null_type: simple(:t)) { CREATE_NODE[:NonNullType, of_type: t, line: t.line, col: t.col] }

      # Values
      rule(array: subtree(:v)) { v }
      rule(array: simple(:v)) { [] } # just `nil`
      rule(boolean: simple(:v)) { v == "true" ? true : false }
      rule(input_object: sequence(:v)) { CREATE_NODE[:InputObject, pairs: v, line: (v.first ? v.first.line : 1), col: (v.first ? v.first.col : 1)] }
      rule(input_object_name: simple(:n), input_object_value: simple(:v)) { CREATE_NODE[:Argument, name: n.to_s, value: v, position_source: n]}
      rule(input_object_name: simple(:n), input_object_value: sequence(:v)) { CREATE_NODE[:Argument, name: n.to_s, value: v, position_source: n]}
      rule(int: simple(:v)) { v.to_i }
      rule(float: simple(:v)) { v.to_f }

      ESCAPES = /\\(["\\\/bfnrt])/
      UTF_8 = /\\u[\da-f]{4}/i
      UTF_8_REPLACE = -> (m) { [m[-4..-1].to_i(16)].pack('U') }

      rule(string: simple(:v)) {
        string = v.to_s
        string.gsub!(ESCAPES, '\1')
        string.gsub!(UTF_8, &UTF_8_REPLACE)
        string
      }
      rule(optional_string_content: simple(:v)) { v.to_s }
      rule(variable: simple(:v)) { CREATE_NODE[:VariableIdentifier, name: v.to_s, position_source: v] }
      rule(enum: simple(:v)) { CREATE_NODE[:Enum, name: v.to_s, position_source: v] }
    end
  end
end
