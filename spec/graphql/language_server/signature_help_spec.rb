# frozen_string_literal: true
require "spec_helper"

describe GraphQL::LanguageServer::SignatureHelp do
  class SignatureHelpTestServer < GraphQL::LanguageServer
    autorun false
    # Silent logger:
    self.logger = Logger.new(StringIO.new)
    # Debugging logger:
    # self.logger = Logger.new($stdout)
    self.schema = Dummy::Schema
  end

  TEST_SERVER = SignatureHelpTestServer.new

  def get_signature_help(filename:, text:, line:, column:, server: TEST_SERVER)
    document_position = GraphQL::LanguageServer::DocumentPosition.new(
      filename: filename,
      text: text,
      line: line,
      column: column,
      server: server,
    )
    suggestion = GraphQL::LanguageServer::SignatureHelp.new(
      document_position: document_position
    )
    suggestion.active_signature
  end

  let(:signature_at) {
    ->(line, col) {
      get_signature_help(filename: filename, text: text, line: line, column: col)
    }
  }

  describe "field signatures" do
    let(:filename) { "scratch.graphql" }
    let(:text) {"
      {
        cheese()
        searchDairy(product: {})
      }
    "}

    it "suggests the current field" do
      signature = signature_at.call(3, 15)
      assert_equal Dummy::Schema.get_field("Query", "cheese"), signature
      signature = signature_at.call(4, 30)
      assert_equal Dummy::DairyProductInputType, signature
    end
  end
end
