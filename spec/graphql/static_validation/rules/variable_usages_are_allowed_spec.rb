# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariableUsagesAreAllowed do
  include StaticValidationHelpers

  let(:query_string) {'
    query getCheese(
        $goodInt: Int = 1,
        $okInt: Int!,
        $badInt: Int,
        $badStr: String!,
        $goodAnimals: [DairyAnimal!]!,
        $badAnimals: [DairyAnimal]!,
        $deepAnimals: [[DairyAnimal!]!]!,
        $goodSource: DairyAnimal!,
    ) {
      goodCheese:   cheese(id: $goodInt)  { source }
      okCheese:     cheese(id: $okInt)    { source }
      badCheese:    cheese(id: $badInt)   { source }
      badStrCheese: cheese(id: $badStr)   { source }
      cheese(id: 1) {
        similarCheese(source: $goodAnimals) { source }
        other: similarCheese(source: $badAnimals) { source }
        tooDeep: similarCheese(source: $deepAnimals) { source }
        nullableCheese(source: $goodAnimals) { source }
        deeplyNullableCheese(source: $deepAnimals) { source }
      }

      milk(id: 1) {
        flavors(limit: $okInt)
      }

      searchDairy(product: [{source: $goodSource}]) {
        ... on Cheese { id }
      }
    }
  '}

  it "finds variables used as arguments but don't match the argument's type" do
    assert_equal(4, errors.length)
    expected = [
      {
        "message"=>"Nullability mismatch on variable $badInt and argument id (Int / Int!)",
        "locations"=>[{"line"=>14, "column"=>28}],
        "fields"=>["query getCheese", "badCheese", "id"],
      },
      {
        "message"=>"Type mismatch on variable $badStr and argument id (String! / Int!)",
        "locations"=>[{"line"=>15, "column"=>28}],
        "fields"=>["query getCheese", "badStrCheese", "id"],
      },
      {
        "message"=>"Nullability mismatch on variable $badAnimals and argument source ([DairyAnimal]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>18, "column"=>30}],
        "fields"=>["query getCheese", "cheese", "other", "source"],
      },
      {
        "message"=>"List dimension mismatch on variable $deepAnimals and argument source ([[DairyAnimal!]!]! / [DairyAnimal!]!)",
        "locations"=>[{"line"=>19, "column"=>32}],
        "fields"=>["query getCheese", "cheese", "tooDeep", "source"],
      }
    ]
    assert_equal(expected, errors)
  end

  describe "input objects that are out of place" do
    let(:query_string) { <<-GRAPHQL
      query getCheese($id: ID!) {
        cheese(id: {blah: $id} ) {
          __typename @nonsense(id: {blah: $id})
          nonsense(id: {blah: {blah: $id}})
        }
      }
    GRAPHQL
    }

    it "adds an error" do
      assert_equal 3, errors.length
      assert_equal "Argument 'id' on Field 'cheese' has an invalid value. Expected type 'Int!'.", errors[0]["message"]
    end
  end

  describe "list-type variables" do
    let(:schema) {
      GraphQL::Schema.from_definition <<-GRAPHQL
      input ImageSize {
        height: Int
        width: Int
        scale: Int
      }

      type Query {
        imageUrl(height: Int, width: Int, size: ImageSize, sizes: [ImageSize!]): String!
        sizedImageUrl(sizes: [ImageSize!]!): String!
      }
      GRAPHQL
    }

    describe "nullability mismatch" do
      let(:query_string) {
        <<-GRAPHQL
        # This variable _should_ be [ImageSize!]
        query ($sizes: [ImageSize]) {
          imageUrl(sizes: $sizes)
        }
        GRAPHQL
      }

      it "finds invalid inner definitions" do
        assert_equal 1, errors.size
        expected_message = "Nullability mismatch on variable $sizes and argument sizes ([ImageSize] / [ImageSize!])"
        assert_equal [expected_message], errors.map { |e| e["message"] }
      end
    end

    describe "list dimension mismatch" do
      let(:query_string) {
        <<-GRAPHQL
        query ($sizes: [ImageSize]) {
          imageUrl(sizes: [$sizes])
        }
        GRAPHQL
      }

      it "finds invalid inner definitions" do
        assert_equal 1, errors.size
        expected_message = "List dimension mismatch on variable $sizes and argument sizes ([[ImageSize]]! / [ImageSize!])"
        assert_equal [expected_message], errors.map { |e| e["message"] }
      end
    end

    describe 'list is in the argument' do
      let(:query_string) {
        <<-GRAPHQL
        query ($size: ImageSize!) {
          imageUrl(sizes: [$size])
        }
        GRAPHQL
      }

      it "is a valid query" do
        assert_equal 0, errors.size
      end

      describe "mixed with invalid literals" do
        let(:query_string) {
          <<-GRAPHQL
          query ($size: ImageSize!) {
            imageUrl(sizes: [$size, 1, true])
          }
          GRAPHQL
        }

        it "is an invalid query" do
          assert_equal 1, errors.size
        end
      end

      describe "mixed with invalid variables" do
        let(:query_string) {
          <<-GRAPHQL
          query ($size: ImageSize!, $wrongSize: Boolean!) {
            imageUrl(sizes: [$size, $wrongSize])
          }
          GRAPHQL
        }

        it "is an invalid query" do
          assert_equal 1, errors.size
        end
      end

      describe "mixed with valid literals and invalid variables" do
        let(:query_string) {
          <<-GRAPHQL
          query ($size: ImageSize!, $wrongSize: Boolean!) {
            imageUrl(sizes: [$size, {height: 100} $wrongSize])
          }
          GRAPHQL
        }

        it "is an invalid query" do
          assert_equal 1, errors.size
        end
      end
    end

    describe 'argument contains a list with literal values' do
      let(:query_string) {
        <<-GRAPHQL
        query  {
          imageUrl(sizes: [{height: 100, width: 100, scale: 1}])
        }
        GRAPHQL
      }

      it "is a valid query" do
        assert_equal 0, errors.size
      end
    end

    describe 'argument contains a list with both literal and variable values' do
      let(:query_string) {
        <<-GRAPHQL
        query($size1: ImageSize!, $size2: ImageSize!)  {
          imageUrl(sizes: [{height: 100, width: 100, scale: 1}, $size1, {height: 1920, width: 1080, scale: 2}, $size2])
        }
        GRAPHQL
      }

      it "is a valid query" do
        assert_equal 0, errors.size
      end
    end

    describe "variable in non-null list" do
      let(:query_string) {
        <<-GRAPHQL
        # This should work
        query ($size: ImageSize!) {
          sizedImageUrl(sizes: [$size])
        }
        GRAPHQL
      }

      it "is allowed" do
        assert_equal [], errors
      end
    end
  end
end
