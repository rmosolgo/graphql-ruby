# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::InputObject do
  let(:input_object) do
    # Cause the arguments_class to be prepared
    Dummy::DairyProductInput.to_graphql

    Dummy::DairyProductInput.new(
      { source: 'COW',  fatContent: 0.8 },
      defaults_used: Set.new,
      context: GraphQL::Query::NullContext)
  end

  describe '#to_json' do
    it 'returns JSON serialized representation of the variables hash' do
      # Regression note: Previously, calling `to_json` on input objects caused stack too deep errors
      assert_equal input_object.to_json, { source: "COW", fat_content: 0.8 }.to_json
    end
  end
end
