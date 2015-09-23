require 'spec_helper'

describe GraphQL::Schema do
  let(:schema) { DummySchema }

  describe "#rescue_from" do
    let(:rescue_middleware) { schema.middleware.first }

    it "adds handlers to the rescue middleware" do
      assert_equal(0, rescue_middleware.rescue_table.length)
      # normally, you'd use a real class, not a symbol:
      schema.rescue_from(:error_class) { "my custom message" }
      assert_equal(1, rescue_middleware.rescue_table.length)
    end
  end
end
