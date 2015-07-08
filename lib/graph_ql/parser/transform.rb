# {Transform} is a [parslet](http://kschiess.github.io/parslet/) transform for for turning the AST into objects in {GraphQL::Syntax}.
class GraphQL::Transform < Parslet::Transform
  # Get syntax classes by shallow name:
  def self.const_missing(constant_name)
    GraphQL::Syntax.const_get(constant_name)
  end

  def self.optional_sequence(name)
    rule(name => simple(:val)) { [] }
    rule(name => sequence(:val)) { val }
  end

  # Document
  rule(document_parts: sequence(:p)) { Document.new(parts: p)}

  # Fragment Definition
  rule(
    fragment_name:  simple(:name),
    type_condition: simple(:type),
    directives:     sequence(:directives),
    selections:     sequence(:selections)
  ) {FragmentDefinition.new(name: name.to_s, type: type, directives: directives, selections: selections)}

  rule(
    fragment_spread_name: simple(:n),
    directives:           sequence(:d)
  ) { FragmentSpread.new(name: n.to_s, directives: d)}

  rule(
    inline_fragment_type: simple(:n),
    directives: sequence(:d),
    selections: sequence(:s),
  ) { InlineFragment.new(type: n, directives: d, selections: s)}

  # Operation Definition
  rule(
    operation_type: simple(:ot),
    name:           simple(:n),
    variables:      sequence(:v),
    directives:     sequence(:d),
    selections:     sequence(:s),
  ) { OperationDefinition.new(operation_type: ot.to_s, name: n.to_s, variables: v, directives: d, selections: s) }
  optional_sequence(:optional_variables)
  rule(variable_name: simple(:n), variable_type: simple(:t), variable_optional_default_value: simple(:v)) { Variable.new(name: n.name, type: t, default_value: v)}
  rule(variable_name: simple(:n), variable_type: simple(:t), variable_optional_default_value: sequence(:v)) { Variable.new(name: n.name, type: t, default_value: v)}
  rule(variable_default_value: simple(:v) ) { v }
  rule(variable_default_value: sequence(:v) ) { v }
  # Query short-hand
  rule(unnamed_selections: sequence(:s)) { OperationDefinition.new(selections: s, operation_type: "query", name: nil, variables: [], directives: [])}

  # Field
  rule(
    alias: simple(:a),
    field_name: simple(:name),
    field_arguments: sequence(:args),
    directives: sequence(:dir),
    selections: sequence(:sel)
  ) { Field.new(alias: a, name: name.to_s, arguments: args, directives: dir, selections: sel) }

  rule(alias_name: simple(:a)) { a.to_s }
  optional_sequence(:optional_field_arguments)
  rule(field_argument_name: simple(:n), field_argument_value: simple(:v)) { FieldArgument.new(name: n.to_s, value: v)}
  optional_sequence(:optional_selections)
  optional_sequence(:optional_directives)

  # Directive
  rule(directive_name: simple(:name), directive_argument: simple(:value)) { Directive.new(name: name.to_s, argument: value) }

  # Values
  rule(array: sequence(:v)) { v }
  rule(boolean: simple(:v)) { v == "true" ? true : false }
  rule(input_object: sequence(:v)) { InputObject.new(pairs: v) }
  rule(input_object_name: simple(:n), input_object_value: simple(:v)) { InputObjectPair.new(name: n.to_s, value: v)}
  rule(int: simple(:v)) { v.to_i }
  rule(float: simple(:v)) { v.to_f }
  rule(string: simple(:v)) { v.to_s }
  rule(variable: simple(:v)) { VariableIdentifier.new(name: v.to_s) }
  rule(enum: simple(:v)) { Enum.new(name: v.to_s)}
end
