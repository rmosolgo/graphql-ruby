# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Template do
  def run_template(erb, helpers: nil)
    GraphQL::Schema::Template.run(erb, helpers: helpers)
  end

  module CustomHelpers
    def search_field(name:, result:)
      "#{name}(search: String): #{result}Connection"
    end
  end

  it "renders the template" do
    template = 'type User { name: <%= "Str" + "ing" %>! }'
    res = run_template(template)
    assert_equal "type User { name: String! }", res
  end

  it "runs built-in helpers" do
    template = "<%= connection('Pizza') %>"
    res = run_template(template)
    expected = "type PizzaConnection {\n  edges: [PizzaEdge!]!\n  pageInfo: PageInfo!\n}\n\ntype PizzaEdge {\n  cursor: ID!\n  node: Pizza!\n}\n"
    assert_equal expected, res
  end

  it "runs a custom helper module too" do
    template = "<% res = 'Book' %><%= search_field(name: 'books', result: res) %>"
    res = run_template(template, helpers: CustomHelpers)
    expected = "books(search: String): BookConnection"
    assert_equal expected, res
  end
end
