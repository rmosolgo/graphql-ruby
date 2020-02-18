# frozen_string_literal: true
require "spec_helper"
require "graphql/types/iso_8601_date"
describe GraphQL::Types::ISO8601Date do
  module DateTest
    class DateObject < GraphQL::Schema::Object
      field :year, Integer, null: false
      field :month, Integer, null: false
      field :day, Integer, null: false
      field :iso8601, GraphQL::Types::ISO8601Date, null: false, method: :itself
    end

    class Query < GraphQL::Schema::Object
      field :parse_date, DateObject, null: true do
        argument :date, GraphQL::Types::ISO8601Date, required: true
      end

      def parse_date(date:)
        # Date is parsed by the scalar, so it's already a DateTime
        date
      end
    end


    class Schema < GraphQL::Schema
      query(Query)
      if TESTING_INTERPRETER
        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
      end
    end
  end


  describe "as an input" do

    def parse_date(date_str)
      query_str = <<-GRAPHQL
      query($date: ISO8601Date!){
        parseDate(date: $date) {
          year
          month
          day
        }
      }
      GRAPHQL
      full_res = DateTest::Schema.execute(query_str, variables: { date: date_str })
      full_res["errors"] || full_res["data"]["parseDate"]
    end

    it "parses valid dates" do
      res = parse_date("2018-06-07")
      expected_res = {
        "year" => 2018,
        "month" => 6,
        "day" => 7,
      }
      assert_equal(expected_res, res)
    end

    it "adds an error for invalid dates" do
      expected_errors = ["Variable $date of type ISO8601Date! was provided invalid value"]

      assert_equal expected_errors, parse_date("2018-26-07").map { |e| e["message"] }
      assert_equal expected_errors, parse_date("xyz").map { |e| e["message"] }
      assert_equal expected_errors, parse_date(nil).map { |e| e["message"] }
    end
  end

  describe "as an output" do
    it "returns a string" do
      query_str = <<-GRAPHQL
      query($date: ISO8601Date!){
        parseDate(date: $date) {
          iso8601
        }
      }
      GRAPHQL

      date_str = "2010-02-02"
      full_res = DateTest::Schema.execute(query_str, variables: { date: date_str })
      assert_equal date_str, full_res["data"]["parseDate"]["iso8601"]
    end
  end

  describe "structure" do
    it "is in introspection" do
      introspection_res = DateTest::Schema.execute <<-GRAPHQL
      {
        __type(name: "ISO8601Date") {
          name
          kind
        }
      }
      GRAPHQL

      expected_res = { "name" => "ISO8601Date", "kind" => "SCALAR"}
      assert_equal expected_res, introspection_res["data"]["__type"]
    end
  end
end
