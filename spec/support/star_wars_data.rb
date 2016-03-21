
names = [
  'X-Wing',
  'Y-Wing',
  'A-Wing',
  'Millenium Falcon',
  'Home One',
  'TIE Fighter',
  'TIE Interceptor',
  'Executor',
]

## Set up "Bases" in ActiveRecord
# ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  self.verbose = false
  create_table :bases do |t|
    t.column :name, :string
    t.column :planet, :string
    t.column :faction_id, :integer
  end
end

class Base < ActiveRecord::Base
end

Base.create!(id: 11, name: "Yavin", planet: "Yavin 4", faction_id: 1)
Base.create!(id: 12, name: "Echo Base", planet: "Hoth", faction_id: 1)
Base.create!(id: 13, name: "Death Star", planet: nil, faction_id: 2)
Base.create!(id: 14, name: "Shield Generator", planet: "Endor", faction_id: 2)
Base.create!(id: 15, name: "Headquarters", planet: "Coruscant", faction_id: 2)


rebels  = OpenStruct.new({
  id: '1',
  name: 'Alliance to Restore the Republic',
  ships:  ['1', '2', '3', '4', '5'],
  bases: Base.where(faction_id: 1),
  basesClone: Base.where(faction_id: 1),
})


empire = OpenStruct.new({
  id: '2',
  name: 'Galactic Empire',
  ships: ['6', '7', '8'],
  bases: Base.where(faction_id: 2),
  basesClone: Base.where(faction_id: 2),
})

STAR_WARS_DATA = {
  "Faction" => {
    "1" => rebels,
    "2" => empire,
  },
  "Ship" => names.each_with_index.reduce({}) do |memo, (name, idx)|
    id = (idx + 1).to_s
    memo[id] = OpenStruct.new(name: name, id: id)
    memo
  end,
  "Base" => Hash.new { |h, k| h[k] = Base.find(k) }
}

def STAR_WARS_DATA.create_ship(name, faction_id)
  new_id = (self["Ship"].keys.map(&:to_i).max + 1).to_s
  new_ship = OpenStruct.new(id: new_id, name: name)
  self["Ship"][new_id] = new_ship
  self["Faction"][faction_id]["ships"] << new_id
  new_ship
end
