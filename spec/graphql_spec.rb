require "spec_helper"

describe GraphQL do
  describe ".validate" do
    it "returns errors on the query string" do
      errors = GraphQL.validate("{ cheese(id: 1) { flavor flavor: id } }", schema: Dummy::Schema)
      assert_equal 1, errors.length
      assert_equal "Field 'flavor' has a field conflict: flavor or id?", errors.first.message

      errors = GraphQL.validate("{ cheese(id: 1) { flavor id } }", schema: Dummy::Schema)
      assert_equal [], errors
    end
  end
end
