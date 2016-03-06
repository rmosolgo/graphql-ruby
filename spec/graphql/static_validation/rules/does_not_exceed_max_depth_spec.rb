require "spec_helper"

describe GraphQL::StaticValidation::DoesNotExceedMaxDepth do
  let(:rule) { GraphQL::StaticValidation::DoesNotExceedMaxDepth }
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [rule]) }
  let(:errors) { validator.validate(GraphQL.parse(query_string)) }

  let(:query_string) { "
    {
      cheese(id: 1) {
        similarCheese(source: SHEEP) {
          similarCheese(source: SHEEP) {
            similarCheese(source: SHEEP) {
              similarCheese(source: SHEEP) {
                similarCheese(source: SHEEP) {
                  id
                }
              }
            }
          }
        }
      }
    }
  "}

  describe "when the query is deeper than max depth" do
    it "adds an error message for a too-deep query" do
      assert_equal 1, errors.length
    end
  end

  describe "When the query is not deeper than max_depth" do
    before do
      @prev_max_depth = DummySchema.max_depth
      DummySchema.max_depth = 100
    end

    after do
      DummySchema.max_depth = @prev_max_depth
    end

    it "doesn't add an error" do
      assert_equal 0, errors.length
    end
  end

  describe "when the max depth isn't set" do
    before do
      @prev_max_depth = DummySchema.max_depth
      DummySchema.max_depth = nil
    end

    after do
      DummySchema.max_depth = @prev_max_depth
    end

    it "doesn't add an error message" do
      assert_equal 0, errors.length
    end
  end
end
