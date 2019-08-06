# frozen_string_literal: true
module GraphQL
  module Compatibility
    module QueryParserSpecification
      module QueryAssertions
        def assert_valid_query(query)
          assert query.is_a?(GraphQL::Language::Nodes::OperationDefinition)
          assert_equal "getStuff", query.name
          assert_equal "query", query.operation_type
          assert_equal 2, query.variables.length
          assert_equal 4, query.selections.length
          assert_equal 1, query.directives.length
          assert_equal [2, 13], [query.line, query.col]
        end

        def assert_valid_fragment(fragment_def)
          assert fragment_def.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
          assert_equal "moreNestedFields", fragment_def.name
          assert_equal 1, fragment_def.selections.length
          assert_equal "NestedType", fragment_def.type.name
          assert_equal 1, fragment_def.directives.length
          assert_equal [20, 13], fragment_def.position
        end

        def assert_valid_variable(variable)
          assert_equal "someVar", variable.name
          assert_equal "Int", variable.type.name
          assert_equal 1, variable.default_value
          assert_equal [2, 28], variable.position
        end

        def assert_valid_field(field)
          assert_equal "someField", field.name
          assert_equal "myField", field.alias
          assert_equal 2, field.directives.length
          assert_equal 2, field.arguments.length
          assert_equal 0, field.selections.length
          assert_equal [3, 15], field.position
        end

        def assert_valid_literal_argument(argument)
          assert_equal "ok", argument.name
          assert_equal 1.4, argument.value
        end

        def assert_valid_variable_argument(argument)
          assert_equal "someArg", argument.name
          assert_equal "someVar", argument.value.name
        end

        def assert_valid_fragment_spread(fragment_spread)
          assert_equal "moreNestedFields", fragment_spread.name
          assert_equal 1, fragment_spread.directives.length
          assert_equal [7, 17], fragment_spread.position
        end

        def assert_valid_directive(directive)
          assert_equal "skip", directive.name
          assert_equal "if", directive.arguments.first.name
          assert_equal 1, directive.arguments.length
          assert_equal [3, 62], directive.position
        end

        def assert_valid_typed_inline_fragment(inline_fragment)
          assert_equal "OtherType", inline_fragment.type.name
          assert_equal 2, inline_fragment.selections.length
          assert_equal 1, inline_fragment.directives.length
          assert_equal [10, 15], inline_fragment.position
        end

        def assert_valid_typeless_inline_fragment(inline_fragment)
          assert_equal nil, inline_fragment.type
          assert_equal 1, inline_fragment.selections.length
          assert_equal 0, inline_fragment.directives.length
        end
      end
    end
  end
end
