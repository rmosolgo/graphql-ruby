# frozen_string_literal: true
require "spec_helper"
require "graphql/execution/next"
describe "Next Execution" do
  class NextExecutionSchema < GraphQL::Schema
    class BaseField < GraphQL::Schema::Field
      def initialize(value: nil, object_method: nil, **kwargs, &block)
        @static_value = value
        @object_method = object_method
        super(**kwargs, &block)
      end

      def resolve_all(objects, context, **arguments)
        if !@static_value.nil?
          Array.new(objects.length, @static_value)
        elsif @object_method
          objects.map { |o| o.public_send(@object_method) }
        else
          @all_method_name ||= :"all_#{method_sym}"
          owner.public_send(@all_method_name, objects, context, **arguments)
        end
      end
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
    end

    module BaseInterface
      include GraphQL::Schema::Interface
      field_class BaseField
    end

    CLEAN_DATA = [
      OpenStruct.new(name: "Legumes", grows_in: ["SPRING", "SUMMER", "FALL"], species: [OpenStruct.new(name: "Snow Pea")]),
      OpenStruct.new(name: "Nightshades", grows_in: ["SUMMER"], species: [OpenStruct.new(name: "Tomato")]),
      OpenStruct.new(name: "Curcurbits", grows_in: ["SUMMER"], species: [OpenStruct.new(name: "Cucumber")])
    ]

    DATA = []

    class Season < GraphQL::Schema::Enum
      value "WINTER"
      value "SPRING"
      value "SUMMER"
      value "FALL"
    end

    module Nameable
      include BaseInterface
      field :name, String, object_method: :name
    end

    class PlantSpecies < BaseObject
      implements Nameable
      field :poisonous, Boolean, value: false
      field :family, "NextExecutionSchema::PlantFamily"

      def self.all_family(objects, context)
        objects.map { |species_obj|
          DATA.find { |f| f.species.include?(species_obj) }
        }
      end

      field :grows_in, [Season]

      def self.all_grows_in(objects, context)
        objects.map { |o| o.grows_in || [] }
      end
    end

    class PlantFamily < BaseObject
      implements Nameable
      field :grows_in, Season, object_method: :grows_in
      field :species, [PlantSpecies], object_method: :species
      field :plant_count, Integer

      def self.all_plant_count(objects, context)
        objects.map { |o| o.species.length }
      end
    end

    class Thing < GraphQL::Schema::Union
      possible_types(PlantFamily, PlantSpecies)
    end

    class Query < BaseObject
      field :families, [PlantFamily], value: DATA

      field :str, String

      def self.all_str(objects, context)
        objects.map { |obj| obj.class.name }
      end

      field :find_species, PlantSpecies do
        argument :name, String
      end

      def self.all_find_species(objects, context, name:)
        species = nil
        DATA.each do |f|
          if (species = f.species.find { |s| s.name == name })
            break
          end
        end
        Array.new(objects.length, species)
      end

      field :all_things, [Thing]

      def self.all_all_things(_objs, _ctx)
        [DATA + DATA.map(&:species).flatten]
      end
    end

    class Mutation < BaseObject
      class CreatePlantInput < GraphQL::Schema::InputObject
        argument :name, String
        argument :family, String
        argument :grows_in, [Season]
      end

      field :create_plant, PlantSpecies do
        argument :input, CreatePlantInput
      end

      def self.all_create_plant(_objs, _ctx, input:)
        name = input[:name]
        family = input[:family]
        grows_in = input[:grows_in]
        family_obj = DATA.find { |f| f.name == family}
        species_obj = OpenStruct.new(name: name, grows_in: grows_in )
        family_obj.species << species_obj
        [species_obj]
      end
    end

    query(Query)
    mutation(Mutation)

    def self.resolve_type(abs_type, obj, ctx)
      if obj.respond_to?(:grows_in)
        PlantFamily
      else
        PlantSpecies
      end
    end
  end


  def run_next(query_str, root_object: nil, variables: {})
    GraphQL::Execution::Next.run(schema: NextExecutionSchema, query_string: query_str, context: {}, variables: variables, root_object: root_object)
  end

  before do
    NextExecutionSchema::DATA.clear
    NextExecutionSchema::DATA.concat(Marshal.load(Marshal.dump(NextExecutionSchema::CLEAN_DATA)))
  end

  it "runs a query" do
    result = run_next("
    query TestNext($name: String) {
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
        # __typename
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
          {"name" => "Legumes", "growsIn" => ["SPRING", "SUMMER", "FALL"]},
          {"name" => "Nightshades", "growsIn" => ["SUMMER"]},
          {"name" => "Curcurbits", "growsIn" => ["SUMMER"]},
          {"name" => "Snow Pea"},
          {"name" => "Tomato"},
          {"name" => "Cucumber"},
        ]
      }
    }
    assert_graphql_equal(expected_result, result)
  end

  it "runs mutations in isolation" do
    result = run_next <<~GRAPHQL
    mutation TestSequence {
      p1: createPlant(input: { name: "Eggplant", family: "Nightshades", growsIn: [SUMMER] }) { growsIn family { plantCount } }
      p2: createPlant(input: { name: "Ground Cherry", family: "Nightshades", growsIn: [SUMMER] }) { growsIn family { plantCount } }
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
end
