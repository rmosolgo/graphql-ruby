require "date"
require "spec_helper"

module Garden
  module DefinePlantBetween
    def self.call(plant, plant_range)
      plant.start_planting_on = plant_range.begin
      plant.end_planting_on = plant_range.end
    end
  end

  class Vegetable
    include GraphQL::Define::InstanceDefinable
    lazy_defined_attr_accessor :name, :start_planting_on, :end_planting_on
    accepts_definitions :name, plant_between: DefinePlantBetween, color: GraphQL::Define.assign_metadata_key(:color)

    # definition added later:
    lazy_defined_attr_accessor :height
  end
end

describe GraphQL::Define::InstanceDefinable do
  describe "extending definitions" do
    before do
      Garden::Vegetable.accepts_definitions(:height)
    end

    after do
      Garden::Vegetable.own_dictionary.delete(:height)
    end

    it "accepts after-the-fact definitions" do
      corn = Garden::Vegetable.define do
        name "Corn"
        height 8
      end

      assert_equal "Corn", corn.name
      assert_equal 8, corn.height
    end
  end

  describe "applying custom definitions" do
    it "uses custom callables" do
      tomato = Garden::Vegetable.define do
        name "Tomato"
        plant_between Date.new(2000, 4, 20)..Date.new(2000, 6, 1)
      end

      assert_equal "Tomato", tomato.name
      assert_equal Date.new(2000, 4, 20), tomato.start_planting_on
      assert_equal Date.new(2000, 6, 1), tomato.end_planting_on
    end
  end

  describe ".define with keywords" do
    it "applies definitions from keywords" do
      okra = Garden::Vegetable.define(name: "Okra", plant_between: Date.new(2000, 5, 1)..Date.new(2000, 7, 1))
      assert_equal "Okra", okra.name
      assert_equal Date.new(2000, 5, 1), okra.start_planting_on
      assert_equal Date.new(2000, 7, 1), okra.end_planting_on
    end
  end

  describe "#define" do
    it "applies new definitions to an object" do
      okra = Garden::Vegetable.define(name: "Okra", plant_between: Date.new(2000, 5, 1)..Date.new(2000, 7, 1))
      assert_equal "Okra", okra.name
      okra.define(name: "Gumbo")
      assert_equal "Gumbo", okra.name
      okra.define { name "Okra" }
      assert_equal "Okra", okra.name
    end
  end

  describe "#redefine" do
    it "re-runs definitions without modifying the original object" do
      arugula = Garden::Vegetable.define(name: "Arugula", color: :green)

      red_arugula = arugula.redefine(color: :red)
      renamed_red_arugula = red_arugula.redefine do
        name "Renamed Red Arugula"
      end

      assert_equal :green, arugula.metadata[:color]
      assert_equal "Arugula", arugula.name

      assert_equal :red, red_arugula.metadata[:color]
      assert_equal "Arugula", red_arugula.name

      assert_equal :red, renamed_red_arugula.metadata[:color]
      assert_equal "Renamed Red Arugula", renamed_red_arugula.name
    end
  end

  describe "#metadata" do
    it "gets values from definitions" do
      arugula = Garden::Vegetable.define(name: "Arugula", color: :green)
      assert_equal :green, arugula.metadata[:color]
    end
  end
end
