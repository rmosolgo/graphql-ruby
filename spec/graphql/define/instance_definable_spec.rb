# frozen_string_literal: true
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
    attr_accessor :name, :start_planting_on, :end_planting_on
    ensure_defined(:name, :start_planting_on, :end_planting_on)
    accepts_definitions :name, plant_between: DefinePlantBetween, has_leaves: GraphQL::Define.assign_metadata_key(:has_leaves), color: GraphQL::Define.assign_metadata_key(:color)

    # definition added later:
    attr_accessor :height
    ensure_defined(:height)

    def color
      metadata[:color]
    end
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

    it "accepts bare definitions" do
      radish = Garden::Vegetable.define do
        name "Radish"
        has_leaves
      end
      assert_equal true, radish.metadata[:has_leaves]
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

    describe "errors in define blocks" do
      it "preserves the definition block to try again" do
        magic_number = 12

        radish = Garden::Vegetable.define {
          name "Pre-error"
          magic_number += 1
          if magic_number == 13
            raise "👻"
          end
          name "Radish"
        }

        # The first call triggers an error:
        assert_raises(RuntimeError) { radish.name }
        # Calling definintion-dependent method should re-run the block,
        # not leave old values around:
        assert_equal "Radish", radish.name
      end
    end
  end

  describe "#redefine" do
    it "re-runs definitions without modifying the original object" do
      arugula = Garden::Vegetable.define(name: "Arugula", color: :green)

      red_arugula = arugula.redefine(color: :red)
      renamed_red_arugula = red_arugula.redefine do
        name "Renamed Red Arugula"
      end

      assert_equal :green, arugula.color
      assert_equal "Arugula", arugula.name

      assert_equal :red, red_arugula.color
      assert_equal "Arugula", red_arugula.name

      assert_equal :red, renamed_red_arugula.color
      assert_equal "Renamed Red Arugula", renamed_red_arugula.name
    end

    it "can be chained several times" do
      arugula_1 = Garden::Vegetable.define(name: "Arugula") { color :green }
      arugula_2 = arugula_1.redefine { color :red }
      arugula_3 = arugula_2.redefine { plant_between(1..3) }
      assert_equal ["Arugula", :green], [arugula_1.name, arugula_1.color]
      assert_equal ["Arugula", :red], [arugula_2.name, arugula_2.color]
      assert_equal ["Arugula", :red], [arugula_3.name, arugula_3.color]
    end
  end

  describe "#metadata" do
    it "gets values from definitions" do
      arugula = Garden::Vegetable.define(name: "Arugula", color: :green)
      assert_equal :green, arugula.metadata[:color]
    end
  end

  describe "#use" do
    class TestPlugin
      attr_reader :target

      def use(defn)
        @target = defn.target
        defn.name('Arugula')
      end
    end

    module TestPluginWithKwargs
      extend self

      def use(defn, name:)
        defn.name(name)
      end
    end

    it "sends a message to the specified plugin's :use method with access to the proxy object and target object" do
      plugin = TestPlugin.new

      arugula = Garden::Vegetable.define do
        use plugin
      end

      assert_equal 'Arugula', arugula.name
      assert_equal arugula, plugin.target
    end

    it "passes kwargs to plugin's `use` method" do
      arugula = Garden::Vegetable.define do
        use TestPluginWithKwargs, name: 'Arugula'
      end

      assert_equal 'Arugula', arugula.name
    end
  end

  describe "typos" do
    it "provides the right class name, method name and line number" do
      err = assert_raises(GraphQL::Define::NoDefinitionError) {
        beet = Garden::Vegetable.define {
          name "Beet"
          nonsense :Blah
        }
        beet.name
      }
      assert_includes err.message, "Garden::Vegetable"
      assert_includes err.message, "nonsense"
      first_backtrace = err.backtrace.first
      # This is the offset from the assertion to the `nonsense` call,
      # it might change when this test changes:
      assert_includes first_backtrace, "#{__LINE__ - 9}"
    end
  end
end
