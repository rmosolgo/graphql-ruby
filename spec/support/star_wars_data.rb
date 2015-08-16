
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

rebels  = OpenStruct.new({
  id: '1',
  name: 'Alliance to Restore the Republic',
  ships:  ['1', '2', '3', '4', '5']
})


empire = OpenStruct.new({
  id: '2',
  name: 'Galactic Empire',
  ships: ['6', '7', '8']
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
  end
}

def STAR_WARS_DATA.create_ship(name, faction_id)
  new_id = (self["Ship"].keys.map(&:to_i).max + 1).to_s
  new_ship = OpenStruct.new(id: new_id, name: name)
  self["Ship"][new_id] = new_ship
  self["Faction"][faction_id]["ships"] << new_id
  new_ship
end
