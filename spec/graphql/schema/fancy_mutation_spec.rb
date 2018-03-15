# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::FancyMutation do
  it "runs with injected args" do
    result = Jazz::Schema.execute('mutation { renameInstrument(id: "0", newName: "Twangeroo") { instrument { name } } }')
    pp result
    assert_equal "Twangeroo", result["data"]["renameInstrument"]["instrument"]["name"]
  end
end
