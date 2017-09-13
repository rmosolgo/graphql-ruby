# frozen_string_literal: true
require "spec_helper"

describe 'Rails dependency sanity check' do
  if rails_should_be_installed?
    it "should have rails installed" do
      assert defined?(Rails)
    end
  else
    it "should not have rails installed" do
      refute defined?(Rails)
    end
  end
end
