
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
#
# var nextShip = 9;
# export function createShip(shipName, factionId) {
#   var newShip = {
#     id: '' + (nextShip++),
#     name: shipName
#   };
#   data.Ship[newShip.id] = newShip;
#   data.Faction[factionId].ships.push(newShip.id);
#   return newShip;
# }
#
# export function getShip(id) {
#   return data.Ship[id];
# }
#
# export function getFaction(id) {
#   return data.Faction[id];
# }
#
# export function getRebels() {
#   return rebels;
# }
#
# export function getEmpire() {
#   return empire;
# }
