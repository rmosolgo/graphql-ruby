require "spec_helper"

describe GraphQL::Schema do
  let(:schema) { DummySchema }
  let(:relay_schema)  { StarWarsSchema }

  describe "#rescue_from" do
    let(:rescue_middleware) { schema.middleware.first }

    it "adds handlers to the rescue middleware" do
      assert_equal(1, rescue_middleware.rescue_table.length)
      # normally, you'd use a real class, not a symbol:
      schema.rescue_from(:error_class) { "my custom message" }
      assert_equal(2, rescue_middleware.rescue_table.length)
    end
  end

  describe "#subscription" do
    it "calls fields on the subscription type" do
      res = schema.execute("subscription { test }")
      assert_equal("Test", res["data"]["test"])
    end
  end

  describe "#resolve_type" do
    describe "when the return value is nil" do
      it "returns nil" do
        result = relay_schema.resolve_type(123, nil)
        assert_equal(nil, result)
      end
    end

    describe "when the return value is not a BaseType" do
      it "raises an error " do
        err = assert_raises(RuntimeError) {
          relay_schema.resolve_type(:test_error, nil)
        }
        assert_includes err.message, "not_a_type (Symbol)"
      end
    end
  end


  describe 'to_global_id / from_global_id' do
    after do
      relay_schema.id_separator = "-"
    end

    it 'Converts typename and ID to and from ID' do
      global_id = relay_schema.to_global_id("SomeType", 123)
      type_name, id = relay_schema.from_global_id(global_id)
      assert_equal("SomeType", type_name)
      assert_equal("123", id)
    end

    it "allows you to change the id_separator" do
      relay_schema.id_separator = "---"

      global_id = relay_schema.to_global_id("Type-With-UUID", "250cda0e-a89d-41cf-99e1-2872d89f1100")
      type_name, id = relay_schema.from_global_id(global_id)
      assert_equal("Type-With-UUID", type_name)
      assert_equal("250cda0e-a89d-41cf-99e1-2872d89f1100", id)
    end

    it "raises an error if you try and use a reserved character in the ID" do
      err = assert_raises(RuntimeError) {
        relay_schema.to_global_id("Best-Thing", "234")
      }
      assert_includes err.message, "to_global_id(Best-Thing, 234) contains reserved characters `-`"
    end
  end
end
