require "spec_helper"

describe GraphQL::Query::SerialExecution::ValueResolution do
  let(:debug) { false }
  let(:query_root) {
    day_of_week_enum = GraphQL::EnumType.define do
      name "DayOfWeek"
      value("MONDAY", value: 0)
      value("TUESDAY", value: 1)
      value("WEDNESDAY", value: 2)
      value("THURSDAY", value: 3)
      value("FRIDAY", value: 4)
      value("SATURDAY", value: 5)
      value("SUNDAY", value: 6)
    end
    GraphQL::ObjectType.define do
      name "Query"
      field :tomorrow, day_of_week_enum do
        argument :today, day_of_week_enum
        resolve ->(obj, args, ctx) { (args["today"] + 1) % 7 }
      end
    end
  }
  let(:schema) { GraphQL::Schema.new(query: query_root) }
  let(:result) { schema.execute(
    query_string,
    debug: debug,
  )}

  describe "enum resolution" do
    let(:query_string) { %|
      {
        tomorrow(today: FRIDAY)
      }
    |}

    it "coerces enum input to the value and result to the name" do
      expected = {
        "data" => {
          "tomorrow" => "SATURDAY"
        }
      }
      assert_equal(expected, result)
    end
  end
end
