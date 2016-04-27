require "spec_helper"

describe GraphQL::Schema::FieldValidator do
  let(:field_defn) {{
    name: "Field",
    description: "Invalid field",
    deprecation_reason: nil,
    arguments: {symbol_arg: nil},
    type: DairyAnimalEnum,
  }}
  let(:field) {
    f = OpenStruct.new(field_defn)
    def f.to_s; f.name; end
    f
  }
  let(:errors) { e = []; GraphQL::Schema::FieldValidator.new.validate(field, e); e }
  it "requires argument names to be strings" do
    expected = ["Field.arguments keys must be Strings, but some aren't: symbol_arg"]
    assert_equal(expected, errors)
  end
end
