require 'spec_helper'

describe GraphQL::InterfaceType do
  let(:interface) { EdibleInterface }
  it 'has possible types' do
    assert_equal([CheeseType, MilkType], interface.possible_types)
  end

  it 'resolves types for objects' do
    assert_equal(CheeseType, interface.resolve_type(CHEESES.values.first))
    assert_equal(MilkType, interface.resolve_type(MILKS.values.first))
  end

  describe 'query evaluation' do
    let(:query) { GraphQL::Query.new(DummySchema, query_string, context: {}, variables: {"cheeseId" => 2})}
    let(:result) { query.result }
    let(:query_string) {%|
      query fav {
        favoriteEdible { fatContent }
      }
    |}
    it 'gets fields from the type for the given object' do
      expected = {"data"=>{"favoriteEdible"=>{"fatContent"=>0.04}}}
      assert_equal(expected, result)
    end
  end

  describe '#resolve_type' do
    let(:interface) {
      GraphQL::InterfaceType.define do
        resolve_type -> (object) {
          return :custom_resolve
        }
      end
    }

    it 'can be overriden in the definition' do
      assert_equal(interface.resolve_type(123), :custom_resolve)
    end
  end
end
