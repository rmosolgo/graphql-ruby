luke = OpenStruct.new({
  id: "1000",
  name: "Luke Skywalker",
  friends: ["1002", "1003", "2000", "2001"],
  appearsIn: [4, 5, 6],
  homePlanet: "Tatooine",
})

vader = OpenStruct.new({
  id: "1001",
  name: "Darth Vader",
  friends: ["1004"],
  appearsIn: [4, 5, 6],
  homePlanet: "Tatooine",
})

han = OpenStruct.new({
  id: "1002",
  name: "Han Solo",
  friends: ["1000", "1003", "2001"],
  appearsIn: [4, 5, 6],
})

leia = OpenStruct.new({
  id: "1003",
  name: "Leia Organa",
  friends: ["1000", "1002", "2000", "2001"],
  appearsIn: [4, 5, 6],
  homePlanet: "Alderaan",
})

tarkin = OpenStruct.new({
  id: "1004",
  name: "Wilhuff Tarkin",
  friends: ["1001"],
  appearsIn: [4],
})

HUMAN_DATA = {
  "1000" => luke,
  "1001" => vader,
  "1002" => han,
  "1003" => leia,
  "1004" => tarkin,
}

threepio = OpenStruct.new({
  id: "2000",
  name: "C-3PO",
  friends: ["1000", "1002", "1003", "2001"],
  appearsIn: [4, 5, 6],
  primaryFunction: "Protocol",
})

artoo = OpenStruct.new({
  id: "2001",
  name: "R2-D2",
  friends: ["1000", "1002", "1003"],
  appearsIn: [4, 5, 6],
  primaryFunction: "Astromech",
})

DROID_DATA = {
  "2000" => threepio,
  "2001" => artoo,
}

# Get friends from IDs
GET_FRIENDS = -> (obj, args, ctx) do
  obj.friends.map { |id| HUMAN_DATA[id] || DROID_DATA[id]}
end
