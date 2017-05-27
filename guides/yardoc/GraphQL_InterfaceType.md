---
layout: doc_stub
search: true
title: GraphQL::InterfaceType
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/InterfaceType
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/InterfaceType
---

Class: GraphQL::InterfaceType < GraphQL::BaseType
An Interface contains a collection of types which implement some of
the same fields. 
Interfaces can have fields, defined with `field`, just like an
object type. 
Objects which implement this field _inherit_ field definitions from
the interface. An object type can override the inherited definition
by redefining that field. 
Examples:
# An interface with three fields
DeviceInterface = GraphQL::InterfaceType.define do
name("Device")
description("Hardware devices for computing")
field :ram, types.String
field :processor, ProcessorType
field :release_year, types.Int
end
# Implementing an interface with an object type
Laptoptype = GraphQL::ObjectType.define do
interfaces [DeviceInterface]
end
Instance methods:
all_fields, get_field, initialize, initialize_copy, kind

