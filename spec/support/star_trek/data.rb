# frozen_string_literal: true
require 'ostruct'

module StarTrek
  names = [
    'USS Enterprise',
    'USS Excelsior',
    'USS Reliant',
    'IKS Koraga',
    'IKS Kronos One',
    'IRW Khazara',
    'IRW Praetus',
  ]

  MONGOID_CONFIG = {
    clients: {
      default: {
        database: 'graphql_ruby_test',
        hosts: ['localhost:27017']
      }
    },
    sessions: {
      default: {
        database: 'graphql_ruby_test',
        hosts: ['localhost:27017']
      }
    }
  }.freeze

  def db_name
    MONGOID_CONFIG[:clients][:default][:database]
  end
  module_function :db_name

  # Set up "Bases" in MongoDB
  Mongoid.load_configuration(MONGOID_CONFIG)

  class Base
    include Mongoid::Document
    field :name, type: String
    field :sector, type: String
    field :faction_id, type: Integer
  end

  Base.collection.drop
  Base.create!(name: "Deep Space Station K-7", sector: "Mempa", faction_id: 1)
  Base.create!(name: "Regula I", sector: "Mutara", faction_id: 1)
  Base.create!(name: "Deep Space Nine", sector: "Bajoran", faction_id: 1)
  Base.create!(name: "Firebase P'ok", sector: nil, faction_id: 2)
  Base.create!(name: "Ganalda Space Station", sector: "Archanis", faction_id: 2)
  Base.create!(name: "Rh'Ihho Station", sector: "Rator", faction_id: 3)

  class FactionRecord
    attr_reader :id, :name, :ships, :bases, :bases_clone
    def initialize(id:, name:, ships:, bases:, bases_clone:)
      @id = id
      @name = name
      @ships = ships
      @bases = bases
      @bases_clone = bases_clone
    end
  end

  federation = FactionRecord.new({
    id: '1',
    name: 'United Federation of Planets',
    ships:  ['1', '2', '3'],
    bases: Base.where(faction_id: 1),
    bases_clone: Base.where(faction_id: 1),
  })

  klingon = FactionRecord.new({
    id: '2',
    name: 'Klingon Empire',
    ships: ['4', '5'],
    bases: Base.where(faction_id: 2),
    bases_clone: Base.where(faction_id: 2),
  })

  romulan = FactionRecord.new({
    id: '2',
    name: 'Romulan Star Empire',
    ships: ['6', '7'],
    bases: Base.where(faction_id: 3),
    bases_clone: Base.where(faction_id: 3),
  })

  DATA = {
    "Faction" => {
      "1" => federation,
      "2" => klingon,
      "3" => romulan,
    },
    "Ship" => names.each_with_index.reduce({}) do |memo, (name, idx)|
      id = (idx + 1).to_s
      memo[id] = OpenStruct.new(name: name, id: id)
      memo
    end,
    "Base" => Hash.new { |h, k| h[k] = Base.find(k) }
  }

  def DATA.create_ship(name, faction_id)
    new_id = (self["Ship"].keys.map(&:to_i).max + 1).to_s
    new_ship = OpenStruct.new(id: new_id, name: name)
    self["Ship"][new_id] = new_ship
    self["Faction"][faction_id].ships << new_id
    new_ship
  end
end
