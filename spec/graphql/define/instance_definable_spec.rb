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
    accepts_definitions :name, plant_between: DefinePlantBetween

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
end
