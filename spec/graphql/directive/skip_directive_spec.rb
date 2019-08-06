# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Directive::SkipDirective do
  let(:directive) { GraphQL::Directive::SkipDirective }
  it "is a default directive" do
    assert directive.default_directive?
  end
end
