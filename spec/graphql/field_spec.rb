require 'spec_helper'

describe GraphQL::Field do
  it 'accepts a proc as type' do
    field = GraphQL::Field.define do
      type(-> { DairyProductUnion })
    end
    assert_equal(DairyProductUnion, field.type)
  end
end
