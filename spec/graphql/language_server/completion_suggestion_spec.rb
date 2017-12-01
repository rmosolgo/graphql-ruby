# frozen_string_literal: true
require "spec_helper"

describe GraphQL::LanguageServer::CompletionSuggestion do
  class CompletionSuggestionTestServer < GraphQL::LanguageServer
    # Silent logger:
    # self.logger = Logger.new(StringIO.new)
    # Debugging logger:
    self.logger = Logger.new($stdout)
    self.schema = Dummy::Schema
  end

  TEST_SERVER = CompletionSuggestionTestServer.new

  def get_suggestions(filename:, text:, line:, column:, server: TEST_SERVER)
    suggestion = GraphQL::LanguageServer::CompletionSuggestion.new(
      filename: filename,
      text: text,
      line: line,
      column: column,
      server: server,
    )
    suggestion.items
  end

  # TODO can you pass params into a let?
  let(:suggestions_at) {
    ->(line, col) {
      get_suggestions(filename: filename, text: text, line: line, column: col)
    }
  }

  describe "in GraphQL code / .graphql files" do
    let(:filename) { "app/scratch.graphql" }
    let(:text) {
      "{ ch }

      "
    }

    it "makes root suggestions" do
      suggestions = suggestions_at.call(2, 0)
      expected_suggestions = [ "query", "mutation", "subscription", "fragment" ]
      assert_equal expected_suggestions, suggestions.map(&:label)
    end

    describe "suggestion fields" do
      it "suggests with partial input" do
        suggestions = suggestions_at.call(1, 4)
        expected_suggestions = ["cheese", "searchDairy"]
        assert_equal expected_suggestions, suggestions.map(&:label)
      end

      it "suggests with all no input" do
        suggestions = suggestions_at.call(1, 2)
        expected_suggestions = Dummy::DairyAppQueryType.all_fields.map(&:name)
        assert_equal expected_suggestions, suggestions.map(&:label)
      end
    end

    describe "suggesting types" do
      let(:text) {
        "query($someInput: I) {     # test input types
          cheese(id: $someInput) {
            ... on                  # test spread scope
          }
        }
        fragment SomeFrag on C      # test valid fragment types
        "
      }

      it "suggests field types for fragment definitions" do
        suggestions = suggestions_at.call(6, 30)
        fragment_conditions_with_C = ["Cheese", "Cow"]
        assert_equal fragment_conditions_with_C, suggestions.map(&:label)
      end

      it "suggests in the current scope for inline fragments"

      it "suggests input types for variable definitions" do
        suggestions = suggestions_at.call(1, 19)
        all_input_type_names_with_I = ["Int", "ID", "DairyProductInput", "ReplaceValuesInput"]
        assert_equal all_input_type_names_with_I, suggestions.map(&:label)
      end
    end

    describe "suggesting variable names" do
      let(:text) {"
        query($cheeseId: ID! $) {     # test suggestion based on usage below
          cheese(id: $c)              # test suggestion based on defn above
          cheese(id: $otherCheeseId)
        }"
      }

      it "suggests them for usages" do
        suggestions = suggestions_at.call(3, 23)
        assert_equal ["$cheeseId"], suggestions.map(&:label)
        # Since the "$" was already added, only the "c" should be updated
        assert_equal ["cheeseId"], suggestions.map(&:insert_text)
      end

      it "suggests them for definitions"
    end

    describe "suggesting fragment names" do
      it "suggests them for usages"
      it "suggests them for definitions"
    end
  end

  describe "in .erb files" do
    it "ignores non-graphql code"
    it "makes suggestions in graphql code"
  end

  describe "in .rb files" do
    it "makes suggestions in <<-GRAPHQL and <<~GRAPHQL heredocs"
    it "makes suggestions in quoted heredocs"
    it "ignores Ruby code before, between and after heredocs"
  end
end
