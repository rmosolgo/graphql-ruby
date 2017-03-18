# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FragmentNamesAreUnique do
  include StaticValidationHelpers

  let(:query_string) {"
    query {
      cheese(id: 1) {
        ... frag1
      }
    }

    fragment frag1 on Cheese { id }
    fragment frag1 on Cheese { id }
  "}

  it "requires unique fragment names" do
    assert_equal(1, errors.length)
    fragment_def_error = {
      "message"=>"Fragment name \"frag1\" must be unique",
      "locations"=>[{"line"=>8, "column"=>5}, {"line"=>9, "column"=>5}],
      "fields"=>[],
    }
    assert_includes(errors, fragment_def_error)
  end
end
