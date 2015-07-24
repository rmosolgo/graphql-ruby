# {Transform} is a [parslet](http://kschiess.github.io/parslet/) transform for for turning the AST into objects in {GraphQL::Nodes} objects.
class GraphQL::Transform < Parslet::Transform
  # Get syntax classes by shallow name:
  include GraphQL::Nodes

  def self.optional_sequence(name)
    rule(name => simple(:val)) { [] }
    rule(name => sequence(:val)) { val }
  end

  # Document
  rule(document_parts: sequence(:p)) { Document.new(parts: p, line: p.first.line, col: p.first.col)}

  # Fragment Definition
  rule(
    fragment_keyword: simple(:kw),
    fragment_name:  simple(:name),
    type_condition: simple(:type),
    directives:     sequence(:directives),
    selections:     sequence(:selections)
  ) {FragmentDefinition.new(name: name.to_s, type: type.to_s, directives: directives, selections: selections, position_source: kw)}

  rule(
    fragment_spread_keyword: simple(:kw),
    fragment_spread_name: simple(:n),
    directives:           sequence(:d)
  ) { FragmentSpread.new(name: n.to_s, directives: d, position_source: kw)}

  rule(
    fragment_spread_keyword: simple(:kw),
    inline_fragment_type: simple(:n),
    directives: sequence(:d),
    selections: sequence(:s),
  ) { InlineFragment.new(type: n.to_s, directives: d, selections: s, position_source: kw)}

  # Operation Definition
  rule(
    operation_type: simple(:ot),
    name:           simple(:n),
    variables:      sequence(:v),
    directives:     sequence(:d),
    selections:     sequence(:s),
  ) { OperationDefinition.new(operation_type: ot.to_s, name: n.to_s, variables: v, directives: d, selections: s, position_source: ot) }
  optional_sequence(:optional_variables)
  rule(variable_name: simple(:n), variable_type: simple(:t), variable_optional_default_value: simple(:v)) { Variable.new(name: n.name, type: t, default_value: v, line: n.line, col: n.col)}
  rule(variable_name: simple(:n), variable_type: simple(:t), variable_optional_default_value: sequence(:v)) { Variable.new(name: n.name, type: t, default_value: v, line: n.line, col: n.col)}
  rule(variable_default_value: simple(:v) ) { v }
  rule(variable_default_value: sequence(:v) ) { v }
  # Query short-hand
  rule(unnamed_selections: sequence(:s)) { OperationDefinition.new(selections: s, operation_type: "query", name: nil, variables: [], directives: [], line: s.first.line, col: s.first.col)}

  # Field
  rule(
    alias: simple(:a),
    field_name: simple(:name),
    field_arguments: sequence(:args),
    directives: sequence(:dir),
    selections: sequence(:sel)
  ) { Field.new(alias: a && a.to_s, name: name.to_s, arguments: args, directives: dir, selections: sel, position_source: [a, name].find { |part| !part.nil? }) }

  rule(alias_name: simple(:a)) { a }
  optional_sequence(:optional_field_arguments)
  rule(field_argument_name: simple(:n), field_argument_value: simple(:v)) { Argument.new(name: n.to_s, value: v, position_source: n)}
  optional_sequence(:optional_selections)
  optional_sequence(:optional_directives)

  # Directive
  rule(directive_name: simple(:name), directive_arguments: sequence(:args)) { Directive.new(name: name.to_s, arguments: args, position_source: name ) }
  rule(directive_argument_name: simple(:n), directive_argument_value: simple(:v)) { Argument.new(name: n.to_s, value: v, position_source: n)}
  optional_sequence(:optional_directive_arguments)

  # Type Defs
  rule(type_name: simple(:n))     { TypeName.new(name: n.to_s, position_source: n) }
  rule(list_type: simple(:t))     { ListType.new(of_type: t, line: t.line, col: t.col)}
  rule(non_null_type: simple(:t)) { NonNullType.new(of_type: t, line: t.line, col: t.col)}

  # Values
  rule(array: sequence(:v)) { v }
  rule(boolean: simple(:v)) { v == "true" ? true : false }
  rule(input_object: sequence(:v)) { InputObject.new(pairs: v, line: v.first.line, col: v.first.col) }
  rule(input_object_name: simple(:n), input_object_value: simple(:v)) { Argument.new(name: n.to_s, value: v, position_source: n)}
  rule(int: simple(:v)) { v.to_i }
  rule(float: simple(:v)) { v.to_f }
  rule(string: simple(:v)) { v.to_s }
  rule(variable: simple(:v)) { VariableIdentifier.new(name: v.to_s, position_source: v) }
  rule(enum: simple(:v)) { Enum.new(name: v.to_s, position_source: v)}
end
