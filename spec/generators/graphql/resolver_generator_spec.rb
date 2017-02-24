require "spec_helper"
require "generators/graphql/resolver_generator"

class GraphQLGeneratorsResolverGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::ResolverGenerator

  test "it generates an empty resolver by name" do
    run_generator(["AttributeResolver"])

    expected_content = <<-RUBY
class Resolvers::AttributeResolver
  def call(obj, args, ctx)
  end
end
RUBY

    assert_file "app/graphql/resolvers/attribute_resolver.rb", expected_content
  end
end
