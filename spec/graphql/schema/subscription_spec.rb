# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Subscription do
  it "generates a return type"
  it "can use a premade `payload_type`"

  describe "#authorized?" do
    it "fails the subscription if it fails the initial check"
    it "unsubscribes if an update fails this check"
  end

  describe "initial subscription" do
    it "calls #subscribe for the initial subscription and returns the result"
    it "rejects the subscription if #subscribe raises an error"
    it "sends no initial response if :no_response is returned"
  end

  describe "updates" do
    it "updates with `object` by default"
    it "updates with the returned value"
    it "skips the update if `:no_update` is returned"
  end

  describe "loads:" do
    it "unsubscribes if a `loads:` argument is not found"
  end
end
