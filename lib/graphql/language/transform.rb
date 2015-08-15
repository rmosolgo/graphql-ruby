class Parslet::Context
  def create_node(name, attributes)
    node_class = GraphQL::Language::Nodes.const_get(name)
    node_class.new(attributes)
  end
end

module GraphQL::Language
  # {Transform} is a [parslet](http://kschiess.github.io/parslet/) transform for for turning the AST into objects in {GraphQL::Language::Nodes} objects.
  class Transform < Parslet::Transform
    def self.optional_sequence(name)
      rule(name => simple(:val)) { [] }
      rule(name => sequence(:val)) { val }
    end



    # Document
    rule(document_parts: sequence(:p)) { create_node(:Document, parts: p, line: (p.first ? p.first.line : 1), col: (p.first ? p.first.col : 1))}
    rule(document_parts: simple(:p)) { create_node(:Document, parts: [], line: 1, col: 1)}

    # Fragment Definition
    rule(
      fragment_keyword: simple(:kw),
      fragment_name:  simple(:name),
      type_condition: simple(:type),
      directives:     sequence(:directives),
      selections:     sequence(:selections)
    ) { create_node(:FragmentDefinition, name: name.to_s, type: type.to_s, directives: directives, selections: selections, position_source: kw)}

    rule(
      fragment_spread_keyword: simple(:kw),
      fragment_spread_name: simple(:n),
      directives:           sequence(:d)
    ) { create_node(:FragmentSpread, name: n.to_s, directives: d, position_source: kw)}

    rule(
      fragment_spread_keyword: simple(:kw),
      inline_fragment_type: simple(:n),
      directives: sequence(:d),
      selections: sequence(:s),
    ) { create_node(:InlineFragment, type: n.to_s, directives: d, selections: s, position_source: kw)}

    # Operation Definition
    rule(
      operation_type: simple(:ot),
      name:           simple(:n),
      variables:      sequence(:v),
      directives:     sequence(:d),
      selections:     sequence(:s),
    ) { create_node(:OperationDefinition, operation_type: ot.to_s, name: n.to_s, variables: v, directives: d, selections: s, position_source: ot) }
    optional_sequence(:optional_variables)
    rule(variable_name: simple(:n), variable_type: simple(:t), variable_optional_default_value: simple(:v)) { create_node(:Variable, name: n.name, type: t, default_value: v, line: n.line, col: n.col)}
    rule(variable_name: simple(:n), variable_type: simple(:t), variable_optional_default_value: sequence(:v)) { create_node(:Variable, name: n.name, type: t, default_value: v, line: n.line, col: n.col)}
    rule(variable_default_value: simple(:v) ) { v }
    rule(variable_default_value: sequence(:v) ) { v }
    # Query short-hand
    rule(unnamed_selections: sequence(:s)) { create_node(:OperationDefinition, selections: s, operation_type: "query", name: nil, variables: [], directives: [], line: s.first.line, col: s.first.col)}

    # Field
    rule(
      alias: simple(:a),
      field_name: simple(:name),
      field_arguments: sequence(:args),
      directives: sequence(:dir),
      selections: sequence(:sel)
    ) { create_node(:Field, alias: a && a.to_s, name: name.to_s, arguments: args, directives: dir, selections: sel, position_source: [a, name].find { |part| !part.nil? }) }

    rule(alias_name: simple(:a)) { a }
    optional_sequence(:optional_field_arguments)
    rule(field_argument_name: simple(:n), field_argument_value: simple(:v)) { create_node(:Argument, name: n.to_s, value: v, position_source: n)}
    rule(field_argument_name: simple(:n), field_argument_value: sequence(:v)) { create_node(:Argument, name: n.to_s, value: v, position_source: n)}
    optional_sequence(:optional_selections)
    optional_sequence(:optional_directives)

    # Directive
    rule(directive_name: simple(:name), directive_arguments: sequence(:args)) { create_node(:Directive, name: name.to_s, arguments: args, position_source: name ) }
    rule(directive_argument_name: simple(:n), directive_argument_value: simple(:v)) { create_node(:Argument, name: n.to_s, value: v, position_source: n)}
    optional_sequence(:optional_directive_arguments)

    # Type Defs
    rule(type_name: simple(:n))     { create_node(:TypeName, name: n.to_s, position_source: n) }
    rule(list_type: simple(:t))     { create_node(:ListType, of_type: t, line: t.line, col: t.col)}
    rule(non_null_type: simple(:t)) { create_node(:NonNullType, of_type: t, line: t.line, col: t.col)}

    # Values
    rule(array: sequence(:v)) { v }
    rule(boolean: simple(:v)) { v == "true" ? true : false }
    rule(input_object: sequence(:v)) { create_node(:InputObject, pairs: v, line: v.first.line, col: v.first.col) }
    rule(input_object_name: simple(:n), input_object_value: simple(:v)) { create_node(:Argument, name: n.to_s, value: v, position_source: n)}
    rule(input_object_name: simple(:n), input_object_value: sequence(:v)) { create_node(:Argument, name: n.to_s, value: v, position_source: n)}
    rule(int: simple(:v)) { v.to_i }
    rule(float: simple(:v)) { v.to_f }
    rule(string: simple(:v)) { v.to_s }
    rule(variable: simple(:v)) { create_node(:VariableIdentifier, name: v.to_s, position_source: v) }
    rule(enum: simple(:v)) { create_node(:Enum, name: v.to_s, position_source: v)}
  end
end
