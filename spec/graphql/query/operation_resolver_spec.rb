require 'spec_helper'

describe GraphQL::Query::OperationResolver do
  let(:operation) { GraphQL.parse("query getCheese($cheeseId: Int!) { cheese(id: $cheeseId) { name }}", as: :operation_definition) }
  let(:params) { {"cheeseId" => 1}}
  let(:query) { OpenStruct.new(params: params, context: nil) }
  let(:resolver) { GraphQL::Query::OperationResolver.new(operation, query)}

  describe "variables" do
    it 'returns variables by name' do
      assert_equal(1, resolver.variables["cheeseId"])
    end
  end
end
