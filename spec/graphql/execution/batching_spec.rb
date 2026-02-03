# frozen_string_literal: true
require "spec_helper"
require "graphql/execution/batching"
describe "Batching Execution" do
  class NextExecutionSchema < GraphQL::Schema
    CLEAN_DATA = [
      OpenStruct.new(name: "Legumes", grows_in: ["SPRING", "🌻", "FALL"], species: [OpenStruct.new(name: "Snow Pea")]),
      OpenStruct.new(name: "Nightshades", grows_in: ["🌻"], species: [OpenStruct.new(name: "Tomato")]),
      OpenStruct.new(name: "Curcurbits", grows_in: ["🌻"], species: [OpenStruct.new(name: "Cucumber")])
    ]

    DATA = []

    class Season < GraphQL::Schema::Enum
      value "WINTER"
      value "SPRING"
      value "SUMMER", value: "🌻"
      value "FALL"
    end

    module Nameable
      include GraphQL::Schema::Interface
      field :name, String
    end

    class PlantSpecies < GraphQL::Schema::Object
      implements Nameable
      field :poisonous, Boolean, resolve_static: :all_poisonous

      def self.all_poisonous(_ctx)
        false
      end

      field :family, "NextExecutionSchema::PlantFamily", resolve_each: :resolve_family

      def self.resolve_family(object, context)
        DATA.find { |f| f.species.include?(object) }
      end

      field :grows_in, [Season], resolve_each: :resolve_grows_in

      def self.resolve_grows_in(object, context)
        object.grows_in || []
      end
    end

    class PlantFamily < GraphQL::Schema::Object
      implements Nameable
      field :name, String, null: false
      field :grows_in, [Season]
      field :species, [PlantSpecies]
      field :plant_count, Integer, resolve_each: :resolve_plant_count

      def self.resolve_plant_count(objects, context)
        objects.species.length.to_f # let it be coerced to int
      end
    end

    class Thing < GraphQL::Schema::Union
      possible_types(PlantFamily, PlantSpecies)
    end

    class Query < GraphQL::Schema::Object
      field :families, [PlantFamily], resolve_static: :resolve_families
      field :nullable_families, [PlantFamily, null: true], resolve_static: :resolve_families

      def self.resolve_families(_ctx)
        DATA
      end

      field :str, String, resolve_batch: :all_str

      def self.all_str(objects, context)
        objects.map { |obj| obj.class.name }
      end

      field :find_species, PlantSpecies, resolve_static: :all_find_species do
        argument :name, String
      end

      def self.all_find_species(context, name:)
        species = nil
        DATA.each do |f|
          if (species = f.species.find { |s| s.name == name })
            break
          end
        end
        species
      end

      field :all_things, [Thing], resolve_static: :resolve_all_things

      def self.resolve_all_things(_ctx)
        DATA + DATA.map(&:species).flatten
      end
    end

    class Mutation < GraphQL::Schema::Object
      class CreatePlantInput < GraphQL::Schema::InputObject
        argument :name, String
        argument :family, String
        argument :grows_in, [Season], default_value: ["🌻"]
      end

      field :create_plant, PlantSpecies, resolve_static: :resolve_create_plant do
        argument :input, CreatePlantInput
      end

      def self.resolve_create_plant( _ctx, input:)
        name = input[:name]
        family = input[:family]
        grows_in = input[:grows_in]
        family_obj = DATA.find { |f| f.name == family}
        species_obj = OpenStruct.new(name: name, grows_in: grows_in )
        family_obj.species << species_obj
        species_obj
      end
    end

    query(Query)
    mutation(Mutation)
    use GraphQL::Execution::Batching

    def self.resolve_type(abs_type, obj, ctx)
      if obj.respond_to?(:grows_in)
        PlantFamily
      else
        PlantSpecies
      end
    end
  end


  def run_next(query_str, root_object: nil, variables: {})
    NextExecutionSchema.execute_batching(query_str, context: {}, variables: variables, root_value: root_object)
  end

  before do
    NextExecutionSchema::DATA.clear
    NextExecutionSchema::DATA.concat(Marshal.load(Marshal.dump(NextExecutionSchema::CLEAN_DATA)))
  end

  it "runs a query" do
    result = run_next("
    query TestNext($name: String!) {
      str
      families {
        ... on Nameable { name }
        ... on PlantFamily { growsIn }
      }
      families { species { name } }
      t: findSpecies(name: $name) { ...SpeciesInfo  ... NameableInfo }
      c: findSpecies(name: \"Cucumber\") { name ...SpeciesInfo }
      x: findSpecies(name: \"Blue Rasperry\") { name }
      allThings {
        __typename
        ... on Nameable { name }
        ... on PlantFamily { growsIn }
      }
    }

    fragment SpeciesInfo on PlantSpecies {
      poisonous
    }

    fragment NameableInfo on Nameable {
      name
    }
    ", root_object: "Abc", variables: { "name" => "Tomato" })
    expected_result = {
      "data" => {
        "str" => "String",
        "families" => [
          {"name" => "Legumes", "growsIn" => ["SPRING", "SUMMER", "FALL"], "species" => [{"name" => "Snow Pea"}]},
          {"name" => "Nightshades", "growsIn" => ["SUMMER"], "species" => [{"name" => "Tomato"}]},
          {"name" => "Curcurbits", "growsIn" => ["SUMMER"], "species" => [{"name" => "Cucumber"}]}
        ],
        "t" => { "poisonous" => false, "name" => "Tomato" },
        "c" => { "name" => "Cucumber", "poisonous" => false },
        "x" => nil,
        "allThings" => [
          {"__typename" => "PlantFamily", "name" => "Legumes", "growsIn" => ["SPRING", "SUMMER", "FALL"]},
          {"__typename" => "PlantFamily", "name" => "Nightshades", "growsIn" => ["SUMMER"]},
          {"__typename" => "PlantFamily", "name" => "Curcurbits", "growsIn" => ["SUMMER"]},
          {"__typename" => "PlantSpecies", "name" => "Snow Pea"},
          {"__typename" => "PlantSpecies", "name" => "Tomato"},
          {"__typename" => "PlantSpecies", "name" => "Cucumber"},
        ]
      }
    }
    assert_graphql_equal(expected_result, result)
  end

  it "runs mutations in isolation" do
    result = run_next <<~GRAPHQL
    mutation TestSequence {
      p1: createPlant(input: { name: "Eggplant", family: "Nightshades", growsIn: [SUMMER] }) { growsIn family { plantCount } }
      p2: createPlant(input: { name: "Ground Cherry", family: "Nightshades" }) { growsIn family { plantCount } }
      p3: createPlant(input: { name: "Potato", family: "Nightshades", growsIn: [SPRING, SUMMER] }) { growsIn family { plantCount } }
    }
    GRAPHQL

    expected_result = { "data" => {
      "p1" => { "growsIn" => ["SUMMER"], "family" => { "plantCount" => 2 }},
      "p2" => { "growsIn" => ["SUMMER"], "family" => { "plantCount" => 3 }},
      "p3" => { "growsIn" => ["SPRING", "SUMMER"], "family" => { "plantCount" => 4 }}
    } }
    assert_graphql_equal(expected_result, result)
  end

  it "runs introspection" do
    result = run_next(GraphQL::Introspection::INTROSPECTION_QUERY)
    new_schema = GraphQL::Schema.from_introspection(result)
    assert_equal NextExecutionSchema.to_definition, new_schema.to_definition
  end

  it "skips and includes" do
    result = run_next <<~GRAPHQL
    {
      c1: findSpecies(name: "Cucumber") @skip(if: true) { name }
      c2: findSpecies(name: "Cucumber") @include(if: false) { name }
      c3: findSpecies(name: "Cucumber") @skip(if: false) { name }
      c4: findSpecies(name: "Cucumber") @include(if: true) { name }
    }
    GRAPHQL

    expected_result = { "data" => {
      "c3" => {"name" => "Cucumber"},
      "c4" => {"name" => "Cucumber"}
    } }
    assert_equal expected_result, result
  end

  it "does scalar coercion" do
    result = run_next <<~GRAPHQL, variables: { input: { name: :Zucchini, family: "Curcurbits", grows_in: "🌻" }}
    mutation TestCoerce($input: CreatePlantInput!) {
      createPlant(input: $input) {
        name
        growsIn
        family { name }
      }
    }
    GRAPHQL

    expected_result = {"errors" =>
      [{"message" =>
        "Variable $input of type CreatePlantInput! was provided invalid value for name (Could not coerce value \"Zucchini\" to String), grows_in (Field is not defined on CreatePlantInput)",
        "locations" => [{"line" => 1, "column" => 21}],
        "extensions" =>
        {"value" =>
          {"name" => :Zucchini, "family" => "Curcurbits", "grows_in" => "🌻"},
          "problems" =>
          [{"path" => ["name"],
            "explanation" => "Could not coerce value \"Zucchini\" to String"},
            {"path" => ["grows_in"],
            "explanation" => "Field is not defined on CreatePlantInput"}]}}]}
    assert_equal expected_result, result
  end

  it "propagates nulls in lists" do
    NextExecutionSchema::DATA << nil
    result = run_next <<~GRAPHQL
      {
        families { name }
        nullableFamilies { name }
      }
    GRAPHQL

    expected_result = {
      "errors" => [
        {
          "message" => "Cannot return null for non-nullable element of type 'PlantFamily' for Query.families",
          "locations" => [{"line" => 2, "column" => 3}],
          "path" => ["families", 3]
        }
      ],
      "data" => {
        "families" => nil,
        "nullableFamilies" => [
          { "name" => "Legumes" },
          { "name" => "Nightshades" },
          { "name" => "Curcurbits" },
          nil,
        ]
      }
    }
    assert_graphql_equal expected_result, result.to_h
  end

  it "propages nulls in objects" do
    NextExecutionSchema::DATA << OpenStruct.new(
      name: nil,
      species: [OpenStruct.new(name: "Artichoke")]
    )

    result = run_next <<-GRAPHQL
      {
        findSpecies(name: "Artichoke") {
          name
          family { name }
        }
      }
    GRAPHQL

    expected_result = {
      "errors" => [{
        "message" => "Cannot return null for non-nullable field PlantFamily.name",
        "locations" => [{"line" => 4, "column" => 20}],
        "path" => ["findSpecies", "family", "name"]
      }],
      "data" => {
        "findSpecies" => {
          "name" => "Artichoke",
          "family" => nil,
        }
      },
    }
    assert_graphql_equal expected_result, result
  end

  it "propages nested nulls in objects in lists" do
    NextExecutionSchema::DATA << OpenStruct.new(
      name: nil,
      species: [OpenStruct.new(name: "Artichoke")]
    )

    result = run_next <<-GRAPHQL
      {
        families {
          ...FamilyInfo
        }
      }

      fragment FamilyInfo on PlantFamily {
        species {
          family {
            ... on Nameable { name }
          }
        }
      }
    GRAPHQL

    expected_result = {
      "errors" => [
        {
          "message" => "Cannot return null for non-nullable field PlantFamily.name",
          "locations" => [{"line" => 10, "column" => 31}],
          "path" => ["families", 3, "species", 0, "family", "name"]
        }
      ],
      "data" => {
        "families" => [
          {"species" => [{"family" => {"name" => "Legumes"}}]},
          {"species" => [{"family" => {"name" => "Nightshades"}}]},
          {"species" => [{"family" => {"name" => "Curcurbits"}}]},
          {"species" => [{"family" => nil}]}
        ]
      },
    }
    assert_equal expected_result, result
  end
end
