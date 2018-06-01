---
layout: guide
doc_stub: false
search: true
section: Types
title: Introduction
desc: GraphQL types and the Ruby DSL
index: 0
---


Types describe objects and values in a system. The API documentation for each type contains a detailed description with examples.

Objects are described with {{ "GraphQL::ObjectType" | api_doc }}s.

Scalar values are described with built-in scalars (string, int, float, boolean, ID) or custom {{ "GraphQL::EnumType" | api_doc }}s. You can define custom {{ "GraphQL::ScalarType" | api_doc }}s, too.

Scalars and enums can be sent to GraphQL as inputs. For complex inputs (key-value pairs), use {{ "GraphQL::InputObjectType" | api_doc }}.

There are two abstract types, too:

- {{ "GraphQL::InterfaceType" | api_doc }} describes a collection of object types which implement some of the same fields.
- {{ "GraphQL::UnionType" | api_doc }} describes a collection of object types which may appear in the same place in the schema (ie, may be returned by the same field.)


{{ "GraphQL::ListType" | api_doc }} and {{ "GraphQL::NonNullType" | api_doc }} modify other types, describing them as "list of _T_" or "required _T_".
