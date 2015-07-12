require 'spec_helper'

describe GraphQL::Schema::TypeValidator do
  let(:object) {
    o = OpenStruct.new({
      description: "...",
      deprecation_reason: nil,
      kind: GraphQL::TypeKinds::OBJECT,
      interfaces: [],
      fields: [],
    })
    def o.to_s; "InvalidType"; end
    o
  }
  let(:validator) { GraphQL::Schema::TypeValidator.new }
  let(:errors) { e = []; validator.validate(object, e); e;}
  it 'requires name' do
    assert_equal(
      ["InvalidType must respond to #name() to be a Type"],
      errors
    )

  end
end
