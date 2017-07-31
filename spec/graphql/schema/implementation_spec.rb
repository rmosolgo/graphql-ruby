# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Implementation do
  def build_schema(graphql_str)
    implementation = GraphQL::Schema::Implementation.new(namespace: TestImplementation)
    schema = GraphQL::Schema.from_definition(graphql_str, default_resolve: implementation)
    implementation.set_schema(schema)
    schema
  end

  module TestImplementation
    class Query
      def initialize(object, context)
      end

      def cards
        [
          CardObject.new("H", 5),
          CardObject.new("S", 6),
          CardObject.new("C", 11),
        ]
      end

      def suit(letter:)
        letter
      end
    end

    class Card
      def initialize(obj, ctx)
        @card = obj
      end

      def is_facecard
        @card.number > 10 || @card.number == 1
      end
    end

    class Suit
      def initialize(letter, context)
        @letter = letter
      end

      NAMES = { "H" => "Hearts", "C" => "Clubs", "S" => "Spades", "D" => "Diamonds"}

      def name
        NAMES[@letter]
      end

      def cards
        1.upto(12) do |i|
          CardObject.new(@letter, i)
        end
      end

      def color
        if @letter == "H" || @letter == "D"
          "RED"
        else
          "BLACK"
        end
      end
    end

    CardObject = Struct.new(:suit, :number)
    SuitObject = Struct.new(:letter)
  end

  describe "building a schema" do
    let(:schema_graphql) { <<~GRAPHQL
    type Query {
      int: Int
      cards: [Card]
      suit(letter: String!): Suit
    }

    type Card {
      suit: Suit
      number: Int
      isFacecard: Boolean
    }

    type Suit {
      letter: String
      name: String
      cards: [Card]
      color: Color
    }

    enum Color {
      RED
      BLACK
    }
    GRAPHQL
    }

    it "builds a working schema" do
      schema = build_schema(schema_graphql)
      res = schema.execute <<~GRAPHQL
        {
          cards {
            suit {
              name
              color
            }
            number
            isFacecard
          }
          suit(letter: "D") {
            name
          }
        }
      GRAPHQL

      expected_data = {
        "cards" => [
          {"suit"=>{"name"=>"Hearts", "color"=>"RED"},  "number"=>5,  "isFacecard"=>false},
          {"suit"=>{"name"=>"Spades", "color"=>"BLACK"},"number"=>6,  "isFacecard"=>false},
          {"suit"=>{"name"=>"Clubs",  "color"=>"BLACK"},"number"=>11, "isFacecard"=>true}
        ],
        "suit"=> {
          "name"=>"Diamonds"
        }
      }

      assert_equal expected_data, res["data"]
    end
  end
end
