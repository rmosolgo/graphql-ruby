---
layout: doc_stub
search: true
title: GraphQL::Define::DefinedObjectProxy
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Define/DefinedObjectProxy
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Define/DefinedObjectProxy
---

Class: GraphQL::Define::DefinedObjectProxy < Object
This object delegates most methods to a dictionary of functions,
@dictionary. @target is passed to the specified function, along with
any arguments and block. This allows a method-based DSL without
adding methods to the defined class. 
Instance methods:
initialize, method_missing, respond_to_missing?, types, use

