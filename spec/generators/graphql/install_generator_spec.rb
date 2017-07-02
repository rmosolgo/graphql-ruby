# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/install_generator"

class GraphQLGeneratorsInstallGeneratorTest < Rails::Generators::TestCase
  tests Graphql::Generators::InstallGenerator
  destination File.expand_path("../../../tmp/dummy", File.dirname(__FILE__))

  setup do
    prepare_destination

    FileUtils.cd(File.join(destination_root, '..')) do
      `rails new dummy --skip-active-record --skip-test-unit --skip-spring --skip-bundle`
    end
  end

  test "it generates a folder structure" do
    run_generator

    assert_file "app/graphql/types/.keep"
    assert_file "app/graphql/mutations/.keep"
    expected_query_route = %|post "/graphql", to: "graphql#execute"|
    expected_graphiql_route = %|
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
|

    assert_file "config/routes.rb" do |contents|
      assert_includes contents, expected_query_route
      assert_includes contents, expected_graphiql_route
    end

    assert_file "Gemfile" do |contents|
      assert_match %r{gem ('|")graphiql-rails('|"), :?group(:| =>) :development}, contents
    end

    expected_schema = <<-RUBY
DummySchema = GraphQL::Schema.define do
  mutation(Types::MutationType)
  query(Types::QueryType)
end
RUBY
    assert_file "app/graphql/dummy_schema.rb", expected_schema


    expected_query_type = <<-RUBY
Types::QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  # TODO: remove me
  field :testField, types.String do
    description \"An example field added by the generator\"
    resolve ->(obj, args, ctx) {
      \"Hello World!\"
    }
  end
end
RUBY

    assert_file "app/graphql/types/query_type.rb", expected_query_type
    assert_file "app/controllers/graphql_controller.rb", EXPECTED_GRAPHQLS_CONTROLLER
  end

  test "it generates graphql-batch and relay boilerplate" do
    run_generator(["--batch", "--relay"])
    assert_file "app/graphql/loaders/.keep"
    assert_file "Gemfile" do |contents|
      assert_match %r{gem ('|")graphql-batch('|")}, contents
    end

    expected_query_type = <<-RUBY
Types::QueryType = GraphQL::ObjectType.define do
  name "Query"
  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  # TODO: remove me
  field :testField, types.String do
    description \"An example field added by the generator\"
    resolve ->(obj, args, ctx) {
      \"Hello World!\"
    }
  end

  field :node, GraphQL::Relay::Node.field
end
RUBY

    assert_file "app/graphql/types/query_type.rb", expected_query_type
    assert_file "app/graphql/dummy_schema.rb", EXPECTED_RELAY_BATCH_SCHEMA
  end

  test "it doesn't install graphiql when API Only" do
    run_generator(['--api'])

    assert_file "Gemfile" do |contents|
      refute_includes contents, "graphiql-rails"
    end

    assert_file "config/routes.rb" do |contents|
      refute_includes contents, "GraphiQL::Rails"
    end
  end

  test "it can skip keeps, skip graphiql and customize schema name" do
    run_generator(["--skip-keeps", "--skip-graphiql", "--schema=CustomSchema"])
    assert_no_file "app/graphql/types/.keep"
    assert_no_file "app/graphql/mutations/.keep"
    assert_file "app/graphql/types"
    assert_file "app/graphql/mutations"
    assert_file "Gemfile" do |contents|
      refute_includes contents, "graphiql-rails"
    end

    assert_file "config/routes.rb" do |contents|
      refute_includes contents, "GraphiQL::Rails"
    end

    assert_file "app/graphql/custom_schema.rb", /CustomSchema = GraphQL::Schema\.define/
    assert_file "app/controllers/graphql_controller.rb", /CustomSchema\.execute/
  end

  EXPECTED_GRAPHQLS_CONTROLLER = <<-RUBY
class GraphqlController < ApplicationController
  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      # current_user: current_user,
    }
    result = DummySchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  end

  private

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: \#{ambiguous_param}"
    end
  end
end
RUBY

  EXPECTED_RELAY_BATCH_SCHEMA = <<-RUBY
DummySchema = GraphQL::Schema.define do

  mutation(Types::MutationType)
  query(Types::QueryType)
  # Relay Object Identification:

  # Return a string UUID for `object`
  id_from_object ->(object, type_definition, query_ctx) {
    # Here's a simple implementation which:
    # - joins the type name & object.id
    # - encodes it with base64:
    # GraphQL::Schema::UniqueWithinType.encode(type_definition.name, object.id)
  }

  # Given a string UUID, find the object
  object_from_id ->(id, query_ctx) {
    # For example, to decode the UUIDs generated above:
    # type_name, item_id = GraphQL::Schema::UniqueWithinType.decode(id)
    #
    # Then, based on `type_name` and `id`
    # find an object in your application
    # ...
  }

  # Object Resolution
  resolve_type -> (obj, ctx) {
    # TODO: Implement this function
    # to return the correct type for `obj`
    raise(NotImplementedError)
  }

  # GraphQL::Batch setup:
  use GraphQL::Batch
end
RUBY
end
