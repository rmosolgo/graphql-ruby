require "spec_helper"

describe GraphQL::InputObjectType do
  let(:input_object) { DairyProductInputType }
  it "has a description" do
    assert(input_object.description)
  end

  it "has input fields" do
    assert(DairyProductInputType.input_fields["fatContent"])
  end

  describe "input validation" do
    it "Accepts anything that yields key-value pairs to #all?" do
      values_obj = MinimumInputObject.new({"source" => "COW", "fatContent" => 0.4})
      assert DairyProductInputType.valid_input?(values_obj)
    end

    describe "validate_input with non-enumerable input" do
      it "returns a valid result for MinimumInputObject" do
        result = DairyProductInputType.validate_input(MinimumInputObject.new({"source" => "COW", "fatContent" => 0.4}))
        assert(result.valid?)
      end

      it "returns an invalid result for MinimumInvalidInputObject" do
        invalid_input = MinimumInputObject.new({"source" => "KOALA", "fatContent" => 0.4})
        result = DairyProductInputType.validate_input(invalid_input)
        assert(!result.valid?)
      end
    end

    describe "validate_input with enumerable input" do
      describe "with good input" do
        let(:input) do
          {
            "source" => "COW",
            "fatContent" => 0.4
          }
        end
        let(:result) { DairyProductInputType.validate_input(input) }

        it "returns a valid result" do
          assert(result.valid?)
        end
      end

      describe "with bad enum and float" do
        let(:result) { DairyProductInputType.validate_input("source" => "KOALA", "fatContent" => "bad_num") }

        it "returns an invalid result" do
          assert(!result.valid?)
        end

        it "has problems with correct paths" do
          paths = result.problems.map { |p| p["path"] }
          assert(paths.include?(["source"]))
          assert(paths.include?(["fatContent"]))
        end

        it "has correct problem explanation" do
          expected = DairyAnimalEnum.validate_input("KOALA").problems[0]["explanation"]

          source_problem = result.problems.detect { |p| p["path"] == ["source"] }
          actual = source_problem["explanation"]

          assert_equal(expected, actual)
        end
      end

      describe "with extra argument" do
        let(:result) { DairyProductInputType.validate_input("source" => "COW", "fatContent" => 0.4, "isDelicious" => false) }

        it "returns an invalid result" do
          assert(!result.valid?)
        end

        it "has problem with correct path" do
          paths = result.problems.map { |p| p["path"] }
          assert_equal(paths, [["isDelicious"]])
        end

        it "has correct problem explanation" do
          assert(result.problems[0]["explanation"].include?("Field is not defined"))
        end
      end

      describe "list with one invalid element" do
        let(:list_type) { GraphQL::ListType.new(of_type: DairyProductInputType) }
        let(:result) do
          list_type.validate_input([
            { "source" => "COW", "fatContent" => 0.4 },
            { "source" => "KOALA", "fatContent" => 0.4 }
          ])
        end

        it "returns an invalid result" do
          assert(!result.valid?)
        end

        it "has one problem" do
          assert_equal(result.problems.length, 1)
        end

        it "has problem with correct path" do
          path = result.problems[0]["path"]
          assert_equal(path, [1, "source"])
        end

        it "has problem with correct explanation" do
          expected = DairyAnimalEnum.validate_input("KOALA").problems[0]["explanation"]
          actual = result.problems[0]["explanation"]
          assert_equal(expected, actual)
        end
      end
    end
  end

  describe "when sent into a query" do
    let(:variables) { {} }
    let(:result) { DummySchema.execute(query_string, variables: variables) }

    describe "list inputs" do
      let(:variables) { {"search" => [MinimumInputObject.new({"source" => "COW", "fatContent" => 0.4})]} }
      let(:query_string) {%|
        query getCheeses($search: [DairyProductInput]!){
            sheep: searchDairy(product: [{source: SHEEP, fatContent: 0.1}]) {
              ... cheeseFields
            }
            cow: searchDairy(product: $search) {
              ... cheeseFields
            }
        }

        fragment cheeseFields on Cheese {
          flavor
        }
      |}

      it "converts items to plain values" do
        sheep_value = result["data"]["sheep"]["flavor"]
        cow_value = result["data"]["cow"]["flavor"]
        assert_equal("Manchego", sheep_value)
        assert_equal("Brie", cow_value)
      end
    end

    describe "scalar inputs" do
      let(:query_string) {%|
        {
          cheese(id: 1.4) {
            flavor
          }
        }
      |}

      it "converts them to the correct type" do
        cheese_name = result["data"]["cheese"]["flavor"]
        assert_equal("Brie", cheese_name)
      end
    end
  end
end
