require 'spec_helper'

describe GraphQL::Query::OperationResolver do
  let(:operation) { GraphQL.parse("query getCheese($cheeseId: 1) { cheese(id: $cheeseId) { name }}", as: :operation_definition) }
  let(:resolver) { GraphQL::Query::OperationResolver.new(operation, nil)}
  describe "variables" do
    it 'returns variables by name' do
      assert_equal(1, resolver.variables["$cheeseId"])
    end
  end
end
