require 'spec_helper'

describe GraphQL::Schema::UnionValidator do
  let(:object) {
    GraphQL::Union.new("Something", "some union", [DairyProductInputType])
  }
  let(:errors) { e = []; GraphQL::Schema::UnionValidator.new.validate(object, e); e;}
  it 'must be 2+ types, must be only object types' do
    expected = [
      "Union Something must be defined with 2 or more types, not 1",
      "Unions can only consist of Object types, but Something has non-object types: DairyProductInput"
    ]
    assert_equal(expected, errors)
  end
end
