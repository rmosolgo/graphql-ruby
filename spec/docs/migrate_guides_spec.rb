# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../tool/docs/migrate_guides"

describe GraphQLDocs::GuideMigrator do
  it "converts front matter and documentation liquid tags" do
    source = <<~MARKDOWN
      ---
      title: Executing Queries
      section: Queries
      ---

      Use {{ "GraphQL::Schema" | api_doc }} and {% internal_link "the guide", "/queries/executing_queries" %}.

      {{ "/images/query.png" | link_to_img:"Query" }}

      {% callout warning %}
      Be careful.
      {% endcallout %}
    MARKDOWN
    result = GraphQLDocs::GuideMigrator.new(paths: []).migrate(source)
    _(result).must_include("# Executing Queries")
    _(result).must_include("[GraphQL::Schema](rdoc-ref:GraphQL::Schema)")
    _(result).must_include("[the guide](/queries/executing_queries)")
    _(result).must_include("![Query](/images/query.png)")
    _(result).must_include("> **Warning:**")
    _(result).wont_include("{{")
    _(result).wont_include("{%")
  end
end
