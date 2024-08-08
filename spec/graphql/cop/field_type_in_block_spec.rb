# frozen_string_literal: true
require 'spec_helper'

describe "GraphQL::Cop::FieldTypeInBlock" do
  include RubocopTestHelpers

  it "finds and autocorrects field corrections with inline types" do
    result = run_rubocop_on("spec/fixtures/cop/field_type.rb")
    assert_equal 3, rubocop_errors(result)

    assert_includes result, <<-RUBY
  field :current_account, Types::Account, null: false, description: "The account of the current viewer"
                          ^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
  field :find_account, Types::Account do
                       ^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
  field(:all_accounts, [Types::Account, null: false]) {
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    RUBY

    assert_rubocop_autocorrects_all("spec/fixtures/cop/field_type.rb")
  end
end
