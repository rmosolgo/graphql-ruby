# frozen_string_literal: true
require "spec_helper"

describe GraphQL::LanguageServer::CompletionSuggestion do
  class CompletionSuggestionTestServer < GraphQL::LanguageServer
    # Silent logger:
    self.logger = Logger.new(StringIO.new)
    # Debugging logger:
    # self.logger = Logger.new($stdout)
    self.schema = Dummy::Schema
  end

  def get_suggestions(filename:, text:, line:, column:, server: CompletionSuggestionTestServer.new)
    document_position = GraphQL::LanguageServer::DocumentPosition.new(
      filename: filename,
      text: text,
      line: line,
      column: column,
      server: server,
    )
    suggestion = GraphQL::LanguageServer::CompletionSuggestion.new(
      document_position: document_position
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

      fragment MilkFields on Milk {
        fl
      }
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

      it "makes suggestions inside fragment definitions" do
        suggestions = suggestions_at.call(4, 10)
        assert_equal ["flavors"], suggestions.map(&:label)
      end

      describe "when arguments were present" do
        let(:text) {"
          query{
            cheese(id: 1) {
              f
            }
          }
        "}

        it "makes proper suggestions" do
          suggestions = suggestions_at.call(4, 15)
          assert_equal ["fatContent", "selfAsEdible", "flavor"], suggestions.map(&:label)
        end
      end

      describe "when no fields are present" do
        let(:text) {"
          query{
            cheese(id: 1) {
              \n            }
          }
        "}

        it "makes proper suggestions" do
          suggestions = suggestions_at.call(4, 14)
          names = Dummy::Schema.types["Cheese"].all_fields.map(&:name)
          assert_equal names.sort, suggestions.map(&:label).sort
        end
      end

      describe "when self_type would be a list" do
        let(:text) {"
          {
            allEdible {
              origin
              f
            }
          }
        "}

        it "suggests fields of the inner type" do
          suggestions = suggestions_at.call(5, 15)
          expected_suggestions = ["fatContent", "selfAsEdible"]
          assert_equal expected_suggestions, suggestions.map(&:label)
        end
      end

      describe "when self_type is invalid" do
        let(:text) {
          "{ ch { t } }

          fragment MilkFields on Bogus {
            fl
          }
          "
        }

        it "suggests nothing" do
          # Bogus field
          assert_equal [], suggestions_at.call(1, 8)
          # Bogus type condition
          assert_equal [], suggestions_at.call(4, 14)
        end
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

      it "suggests in the current scope for inline fragments" do
        suggestions = suggestions_at.call(3, 18)
        overlapping_types = ["Cheese", "Edible", "EdibleAsMilk", "AnimalProduct", "LocalProduct"]
        assert_equal overlapping_types, suggestions.map(&:label)
      end

      it "suggests input types for variable definitions" do
        suggestions = suggestions_at.call(1, 19)
        all_input_type_names_with_I = ["Int", "ID", "DairyProductInput", "ReplaceValuesInput"]
        assert_equal all_input_type_names_with_I, suggestions.map(&:label)
      end
    end

    describe "suggesting variable names" do
      let(:text) {"
        query($cheeseId: ID!) {
          cheese(id: $c)        # test suggestion based on defn above
        }"
      }

      it "suggests them for usages" do
        suggestions = suggestions_at.call(3, 23)
        assert_equal ["$cheeseId"], suggestions.map(&:label)
        # Since the "$" was already added, only the "c" should be updated
        assert_equal ["cheeseId"], suggestions.map(&:insert_text)
      end
    end

    describe "suggesting fragment names" do
      it "suggests them for usages, according to current scope" do
        skip "This requires scanning beyond the cursor; we're not gonna do it yet."
      end
    end
  end

  describe "in .erb files" do
    let(:filename) { "app/scratch.erb" }
    let(:text) {
      "<h1><%= heading %></h1>
      <%graphql
        fragment on Cheese {
          id
          fl
        }
      %>
      <p>body</p>
      "
    }

    it "ignores non-graphql code" do
      assert_equal [], suggestions_at.call(1,5)
      assert_equal [], suggestions_at.call(8,17)
    end

    it "makes suggestions in graphql code" do
      suggestions = suggestions_at.call(5,12)
      expected_suggestions = ["flavor"]
      assert_equal expected_suggestions, suggestions.map(&:label)
    end
  end

  describe "in .rb files" do
    it "makes suggestions in <<-GRAPHQL and <<~GRAPHQL heredocs"
    it "makes suggestions in quoted heredocs"
    it "ignores Ruby code before, between and after heredocs"
  end
end
