# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../tool/docs/migrate_yard"

describe GraphQLDocs::YardMigrator do
  def migrate(source)
    path = File.join(Dir.tmpdir, "graphql-ruby-doc-fixture-#{Process.pid}.rb")
    File.write(path, source)
    result = GraphQLDocs::YardMigrator.new(paths: [path]).migrate_file(path)
    [result, path]
  end

  it "converts parameters, returns, raises, examples, and links" do
    source = <<~RUBY
      # Execute a query.
      #
      # @param query [String] The query string.
      # @param variables [Hash, nil] Variables.
      # @return [GraphQL::Query::Result, nil] The result.
      # @raise [GraphQL::Error] When execution fails.
      # @example Execute a query
      #   Schema.execute("{ viewer { id } }")
      # @see {GraphQL::Schema#execute execution}.
      def execute(query, variables = nil); end
    RUBY
    result, path = migrate(source)
    _(result.unknown).must_be_empty
    _(result.pending).must_be_empty
    _(result.content).must_include("**Parameters**")
    _(result.content).must_include("- `query` (`String`) — The query string.")
    _(result.content).must_include("- `variables` (`Hash, nil`) — Variables.")
    _(result.content).must_include("**Returns**")
    _(result.content).must_include("**Raises**")
    _(result.content).must_include("**Example: Execute a query**")
    _(result.content).must_include("[execution](rdoc-ref:GraphQL::Schema#execute)")
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  it "handles relative links and multiline descriptions" do
    source = <<~RUBY
      # A result.
      #
      # @param options [Hash] First line
      #   second line.
      # @return [Object]
      # @see {#result}
      def result(options); end
    RUBY
    result, path = migrate(source)
    _(result.content).must_include("First line")
    _(result.content).must_include("[result](rdoc-ref:#result)")
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  it "reports unsupported and unknown tags without deleting them" do
    source = <<~RUBY
      # @abstract
      # @unknown value
      def hidden; end
    RUBY
    result, path = migrate(source)
    _(result.pending.join).must_include("@abstract")
    _(result.unknown.join).must_include("@unknown")
    _(result.content).must_include("@abstract")
    _(result.content).must_include("@unknown value")
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  it "is idempotent after conversion" do
    source = <<~RUBY
      # @param value [String] A value.
      def value(value); end
    RUBY
    result, path = migrate(source)
    File.write(path, result.content)
    second = GraphQLDocs::YardMigrator.new(paths: [path]).migrate_file(path)
    _(second.content).must_equal(result.content)
    _(second.changed).must_equal(false)
  ensure
    File.delete(path) if path && File.exist?(path)
  end
end
