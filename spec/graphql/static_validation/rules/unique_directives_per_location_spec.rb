# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::UniqueDirectivesPerLocation do
  include StaticValidationHelpers

  let(:schema) { GraphQL::Schema.from_definition("
    type Query {
      type: Type
    }

    type Type {
      field: String
    }

    directive @A on FIELD
    directive @B on FIELD
  ") }

  describe "query with no directives" do
    let(:query_string) {"
      {
        type {
          field
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with unique directives in different locations" do
    let(:query_string) {"
      {
        type @A {
          field @B
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with unique directives in same locations" do
    let(:query_string) {"
      {
        type @A @B {
          field @A @B
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with same directives in different locations" do
    let(:query_string) {"
      {
        type @A {
          field @A
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with same directives in similar locations" do
    let(:query_string) {"
      {
        type {
          field @A
          field @A
        }
      }
    "}

    it "passes rule" do
      assert_equal [], errors
    end
  end

  describe "query with duplicate directives in one location" do
    let(:query_string) {"
      {
        type {
          field @A @A
        }
      }
    "}

    it "fails rule" do
      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 20 }],
        "fields" => ["query", "type", "field"],
      }
    end
  end


  describe "query with many duplicate directives in one location" do
    let(:query_string) {"
      {
        type {
          field @A @A @A
        }
      }
    "}

    it "fails rule" do
      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 20 }],
        "fields" => ["query", "type", "field"],
      }

      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 23 }],
        "fields" => ["query", "type", "field"],
      }
    end
  end

  describe "query with different duplicate directives in one location" do
    let(:query_string) {"
      {
        type {
          field @A @B @A @B
        }
      }
    "}

    it "fails rule" do
      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 23 }],
        "fields" => ["query", "type", "field"],
      }

      assert_includes errors, {
        "message" => 'The directive "B" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 20 }, { "line" => 4, "column" => 26 }],
        "fields" => ["query", "type", "field"],
      }
    end
  end

  describe "query with duplicate directives in many locations" do
    let(:query_string) {"
      {
        type @A @A {
          field @A @A
        }
      }
    "}

    it "fails rule" do
      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 3, "column" => 14 }, { "line" => 3, "column" => 17 }],
        "fields" => ["query", "type"],
      }

      assert_includes errors, {
        "message" => 'The directive "A" can only be used once at this location.',
        "locations" => [{ "line" => 4, "column" => 17 }, { "line" => 4, "column" => 20 }],
        "fields" => ["query", "type", "field"],
      }
    end
  end
end
