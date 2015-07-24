require 'spec_helper'

describe GraphQL::Enum do
  let(:enum) { DairyAnimalEnum }

  it 'coerces names to underlying values' do
    assert_equal("YAK", enum.coerce("YAK"))
    assert_equal(1, enum.coerce("COW"))
  end
end
