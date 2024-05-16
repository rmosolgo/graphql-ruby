require 'spec_helper'
require 'rust_graphql_parser'
require 'benchmark/ips'
require 'graphql/c_parser'

describe 'Parsing' do
  %w[
    big_query
    directive_args
    directive_args_multiline
    field_arguments
    fragment
    fragment_spread
    inline_fragment
    inline_fragment_dir
    minimal
    minimal_mutation
    minimal_query
    mutation_directive
    mutation_nameless_vars
    named_query
    nested_field_arguments
    nested_selection
    query_aliases
    query_arguments
    query_arguments_multiline
    query_array_argument_multiline
    query_directive
    query_list_argument
    query_nameless_vars
    query_nameless_vars_multiple_fields
    query_nameless_vars_multiple_fields_canonical
    query_object_argument
    query_object_argument_multiline
    query_var_default_float
    query_var_default_list
    query_var_default_object
    query_var_default_string
    query_var_defaults
    query_vars
    string_literal
    subscription_directive
    types
  ].each do |filename|
    specify filename do
      source = File.read("spec/data/#{filename}.graphql")
      ruby_ast = GraphQL.parse(source)
      # pp ruby_ast
      rust_ast = RustGraphqlParser.parse(source)
      # pp rust_ast
      expect(rust_ast).to eq(ruby_ast)
    end
  end
end
