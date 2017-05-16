---
layout: doc_stub
search: true
title: GraphQL::Language::Nodes::AbstractNode
url: http://www.rubydoc.info/gems/graphql/GraphQL/Language/Nodes/AbstractNode
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Language/Nodes/AbstractNode
---

Class: GraphQL::Language::Nodes::AbstractNode < Object
AbstractNode is the base class for all nodes in a GraphQL AST. 
It provides some APIs for working with ASTs: - `children` returns
all AST nodes attached to this one. Used for tree traversal. -
`scalars` returns all scalar (Ruby) values attached to this one.
Used for comparing nodes. - `to_query_string` turns an AST node into
a GraphQL string 
Direct Known Subclasses:
Argument, Directive, DirectiveDefinition, Document, EnumTypeDefinition,
EnumValueDefinition, Field, FieldDefinition, FragmentDefinition,
FragmentSpread, InlineFragment, InputObject, InputObjectTypeDefinition,
InputValueDefinition, InterfaceTypeDefinition, NameOnlyNode,
ObjectTypeDefinition, OperationDefinition, ScalarTypeDefinition,
SchemaDefinition, UnionTypeDefinition, VariableDefinition, WrapperType
Class methods:
child_attributes, inherited, scalar_attributes
Instance methods:
children, eql?, initialize, initialize_node, position, scalars,
to_query_string

