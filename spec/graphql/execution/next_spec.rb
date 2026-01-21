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

    ALL_FAMILIES = [
      OpenStruct.new(name: "Legumes", grows_in: ["SPRING", "SUMMER", "FALL"], species: [OpenStruct.new(name: "Snow Pea")]),
      OpenStruct.new(name: "Nightshades", grows_in: ["SUMMER"], species: [OpenStruct.new(name: "Tomato")]),
      OpenStruct.new(name: "Curcurbits", grows_in: ["SUMMER"], species: [OpenStruct.new(name: "Cucumber")])
    ]

    class Season < GraphQL::Schema::Enum
      value "WINTER"
      value "SPRING"
      value "SUMMER"
      value "FALL"
    end

    class Species < BaseObject
      field :name, String, object_method: :name
    end

    class PlantFamily < BaseObject
      field :name, String, object_method: :name
      field :grows_in, Season, object_method: :grows_in
      field :species, [Species], object_method: :species
    end


    class Query < BaseObject
      field :families, [PlantFamily], value: ALL_FAMILIES

      field :str, String

      def self.all_str(objects, context)
        objects.map { |obj| obj.class.name }
      end

      field :find_species, Species do
        argument :name, String
      end

      def self.all_find_species(objects, context, name:)
        species = nil
        ALL_FAMILIES.each do |f|
          if (species = f.species.find { |s| s.name == name })
            break
          end
        end
        Array.new(objects.length, species)
      end
    end

    query(Query)
  end


  def run_next(query_str, root_object: nil)
    GraphQL::Execution::Next.run(schema: NextExecutionSchema, query_string: query_str, context: {}, variables: {}, root_object: root_object)
  end

  it "runs a query" do
    result = run_next("{
      str
      families { name growsIn species { name } }
      t: findSpecies(name: \"Tomato\") { name }
      c: findSpecies(name: \"Cucumber\") { name }
      x: findSpecies(name: \"Blue Rasperry\") { name }
    }", root_object: "Abc")
    expected_result = {
      "data" => {
        "str" => "String",
        "families" => [
          {"name" => "Legumes", "growsIn" => ["SPRING", "SUMMER", "FALL"], "species" => [{"name" => "Snow Pea"}]},
          {"name" => "Nightshades", "growsIn" => ["SUMMER"], "species" => [{"name" => "Tomato"}]},
          {"name" => "Curcurbits", "growsIn" => ["SUMMER"], "species" => [{"name" => "Cucumber"}]}
        ],
        "t" => { "name" => "Tomato" },
        "c" => { "name" => "Cucumber" },
        "x" => nil
      }
    }
    assert_equal(expected_result, result)
  end
end
