---
layout: doc_stub
search: true
title: GraphQL::Define::InstanceDefinable
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Define/InstanceDefinable
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Define/InstanceDefinable
---

Module: GraphQL::Define::InstanceDefinable
This module provides the `.define { ... }` API for
GraphQL::BaseType, GraphQL::Field and others. 
Calling `.accepts_definitions(...)` creates: 
- a keyword to the `.define` method - a helper method in the
`.define { ... }` block 
The `.define { ... }` block will be called lazily. To be sure it has
been called, use the private method `#ensure_defined`. That will
call the definition block if it hasn't been called already. 
The goals are: 
- Minimal overhead in consuming classes - Independence between
consuming classes - Extendable by third-party libraries without
monkey-patching or other nastiness 
Examples:
# Make a class definable
class Car
include GraphQL::Define::InstanceDefinable
attr_accessor :make, :model, :doors
accepts_definitions(
# These attrs will be defined with plain setters, `{attr}=`
:make, :model,
# This attr has a custom definition which applies the config to the target
doors: ->(car, doors_count) { doors_count.times { car.doors << Door.new } }
)
ensure_defined(:make, :model, :doors)
def initialize
@doors = []
end
end
class Door; end;
# Create an instance with `.define`:
subaru_baja = Car.define do
make "Subaru"
model "Baja"
doors 4
end
# The custom proc was applied:
subaru_baja.doors #=> [<Door>, <Door>, <Door>, <Door>]
# Extending the definition of a class
# Add some definitions:
Car.accepts_definitions(all_wheel_drive: GraphQL::Define.assign_metadata_key(:all_wheel_drive))
# Use it in a definition
subaru_baja = Car.define do
# ...
all_wheel_drive true
end
# Access it from metadata
subaru_baja.metadata[:all_wheel_drive] # => true
# Extending the definition of a class via a plugin
# A plugin is any object that responds to `.use(definition)`
module SubaruCar
extend self
def use(defn)
# `defn` has the same methods as within `.define { ... }` block
defn.make "Subaru"
defn.doors 4
end
end
# Use the plugin within a `.define { ... }` block
subaru_baja = Car.define do
use SubaruCar
model 'Baja'
end
subaru_baja.make # => "Subaru"
subaru_baja.doors # => [<Door>, <Door>, <Door>, <Door>]
# Making a copy with an extended definition
# Create an instance with `.define`:
subaru_baja = Car.define do
make "Subaru"
model "Baja"
doors 4
end
# Then extend it with `#redefine`
two_door_baja = subaru_baja.redefine do
doors 2
end
Defined Under Namespace:
ClassMethods (modules)
AssignAttribute, AssignMetadataKey, Definition (classes)
Class methods:
included
Instance methods:
define, ensure_defined, initialize_copy, metadata, redefine,
revive_dependent_methods, stash_dependent_methods

