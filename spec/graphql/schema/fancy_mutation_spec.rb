# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::FancyMutation do
  let(:query_string) {
    <<-GRAPHQL
    mutation($id: ID!, $newName: String!){
      renameInstrument(id: $id, newName: $newName) {
        instrument {
          name
        }
        userErrors {
          message
          fields
        }
      }
    }
    GRAPHQL
  }
  describe "argument preparation" do
    it "runs with injected args" do
      result = Jazz::Schema.execute(query_string, variables: { "id" => "0", "newName" => "Twangeroo"})

      assert_equal "Twangeroo", result["data"]["renameInstrument"]["instrument"]["name"]
    end

    it "handles UserErrors during preparation" do
      result = Jazz::Schema.execute('mutation { renameInstrument(id: "999", newName: "Twangeroo") { instrument { name } userErrors { message fields } } }')

      mutation_result = result["data"]["renameInstrument"]
      assert_equal nil, mutation_result["instrument"]
      expected_error = "Instrument not found for \"999\""
      assert_equal expected_error, mutation_result["userErrors"][0]["message"]
      assert_equal ["renameInstrument", "id"], mutation_result["userErrors"][0]["fields"]
    end
  end

  describe "auth before performing" do
    it "can be halted by a UserError" do
      result = Jazz::Schema.execute(query_string, variables: { "id" => "0", "newName" => "Banjo"})

      mutation_result = result["data"]["renameInstrument"]
      assert_equal nil, mutation_result["instrument"]

      expected_error = "Can't rename an instrument to the same name"
      assert_equal expected_error, mutation_result["userErrors"][0]["message"]
      assert_equal ["renameInstrument"], mutation_result["userErrors"][0]["fields"]
    end
  end

  describe "user errors during mutate" do
    it "halts and returns a userError" do
      result = Jazz::Schema.execute(query_string, variables: { "id" => "3", "newName" => "Harpsichord"})

      mutation_result = result["data"]["renameInstrument"]
      assert_equal nil, mutation_result["instrument"]

      expected_error = "Can't rename Piano"
      assert_equal expected_error, mutation_result["userErrors"][0]["message"]
      assert_equal ["renameInstrument"], mutation_result["userErrors"][0]["fields"]
    end
  end
end
