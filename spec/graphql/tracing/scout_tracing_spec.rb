# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Tracing::ScoutTracing do
  class ScoutApm
    module Tracer
    end
  end

  describe "Initializing" do
    it "should include the module only after initilization" do
      refute GraphQL::Tracing::ScoutTracing.included_modules.include?(ScoutApm::Tracer)
      assert GraphQL::Tracing::ScoutTracing.new.class.included_modules.include?(ScoutApm::Tracer)
    end
  end
end