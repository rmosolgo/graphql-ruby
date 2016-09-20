require "spec_helper"

describe GraphQL::StaticValidation::Validator do
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }


  describe "validation order" do
    let(:document) { GraphQL.parse(query_string)}

    describe "fields & arguments" do
      let(:query_string) { %|
        query getCheese($id: Int!) {
          cheese(id: $undefinedVar, bogusArg: true) {
            source,
            nonsenseField,
            id(nonsenseArg: 1)
            bogusField(bogusArg: true)
          }

          otherCheese: cheese(id: $id) {
            source,
          }
        }
      |}

      it "handles args on invalid fields" do
        # nonsenseField, nonsenseArg, bogusField, bogusArg, undefinedVar
        assert_equal(5, errors.length)
      end
    end

    describe "infinite fragments" do
      let(:query_string) { %|
        query getCheese {
          cheese(id: 1) {
            ... cheeseFields
          }
        }
        fragment cheeseFields on Cheese {
          ... on Cheese {
            id, ... cheeseFields
          }
        }
      |}

      it "handles infinite fragment spreads" do
        assert_equal(1, errors.length)
      end

      describe "nested spreads" do
        let(:query_string) {%|
        {
          allEdible {
            ... on Cheese {
              ... cheeseFields
            }
          }
        }

        fragment cheeseFields on Cheese {
          similarCheese(source: COW) {
            similarCheese(source: COW) {
              ... cheeseFields
            }
          }
        }
        |}

        it "finds an error on the nested spread" do
          expected = [
            {
              "message"=>"Fragment cheeseFields contains an infinite loop",
              "locations"=>[{"line"=>10, "column"=>9}],
              "path"=>["fragment cheeseFields"]
            }
          ]
          assert_equal(expected, errors)
        end
      end
    end

    describe "fragment spreads with no selections" do
      let(:query_string) {%|
        query SimpleQuery {
          cheese(id: 1) {
            # OK:
            ... {
              id
            }
            # NOT OK:
            ...cheeseFields
          }
        }
      |}
      it "marks an error" do
        assert_equal(1, errors.length)
      end
    end

    describe "fragments with no names" do
      let(:query_string) {%|
        fragment on Cheese {
          id
          flavor
        }
      |}
      it "marks an error" do
        assert_equal(1, errors.length)
      end
    end
  end
end
