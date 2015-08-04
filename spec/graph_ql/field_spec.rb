require 'spec_helper'

describe GraphQL::Field do
  it 'accepts a proc as type' do
    field = GraphQL::Field.new { |f|
      f.type(-> { DairyProductUnion })
    }
    assert_equal(DairyProductUnion, field.type)
  end
end
