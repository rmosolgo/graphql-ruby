require 'spec_helper'

describe GraphQL::InputObjectType do
  let(:input_object) { DairyProductInputType }
  it 'has a description' do
    assert(input_object.description)
  end

  it 'has input fields' do
    assert(DairyProductInputType.input_fields["fatContent"])
  end
end
