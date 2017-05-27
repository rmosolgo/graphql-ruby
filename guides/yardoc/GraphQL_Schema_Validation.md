---
layout: doc_stub
search: true
title: GraphQL::Schema::Validation
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/Validation
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/Validation
---

Class: GraphQL::Schema::Validation < Object
This module provides a function for validating GraphQL types. 
Its RULES contain objects that respond to `#call(type)`. Rules are
looked up for given types (by class ancestry), then applied to the
object until an error is returned. 
Class methods:
validate

