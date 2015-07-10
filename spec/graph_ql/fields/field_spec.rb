require 'spec_helper'

describe GraphQL::Field do
  it 'requires type' do
    assert_raises(ArgumentError) { GraphQL::Field.new {|f| f.name("MyField"); f.description("My desc") }}
  end
end
