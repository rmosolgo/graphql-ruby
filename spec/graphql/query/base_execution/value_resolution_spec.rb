require 'spec_helper'

describe GraphQL::Query::BaseExecution::ValueResolution do
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
        resolve ->(obj, args, ctx) { (args['today'] + 1) % 7 }
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

  describe "value resolution" do
    let(:schema) {
      # raise if self is not a Field
      ValueQueryType = GraphQL::ObjectType.define do
        name "Query"
        field :dairy do
          type DairyType
          resolve -> (t, a, c) {
            raise self.to_s unless self == ValueQueryType.fields["dairy"]
            DAIRY
          }
        end
      end

      GraphQL::Schema.new(query: ValueQueryType, mutation: MutationType)
    }
    let(:query_string) { %|
      query getDairy {
        dairy {
          id
          ... on Dairy {
            id
          }
          ...repetitiveFragment
        }
      }
      fragment repetitiveFragment on Dairy {
        id
      }
    |}

    it "executes resolution proc in the context of a field" do
      expected = {"data" => {
        "dairy" => { "id" => "1" }
      }}
      assert_equal(expected, result)
    end
  end
end
