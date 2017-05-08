---
layout: guide
title: Queries — Phases of Execution
---

When GraphQL receives a query string, it goes through these steps:

- Tokenize: {{ "GraphQL::Language::Lexer" | api_doc }} splits the string into a stream of tokens
- Parse: {{ "GraphQL::Language::Parser" | api_doc }} builds an abstract syntax tree (AST) out of the stream of tokens
- Validate: {{ "GraphQL::StaticValidation::Validator" | api_doc }} validates the incoming AST as a valid query for the schema
- Rewrite: {{ "GraphQL::InternalRepresentation::Rewrite" | api_doc }} builds a tree of {{ "GraphQL::InternalRepresentation::Node" | api_doc }}s which express the query in a simpler way than the AST
- Analyze: If there are any query analyzers, they are run with {{ "GraphQL::Analysis::AnalyzeQuery" | api_doc }}
- Execute: The query is traversed, {{ "resolve" | api_doc }} functions are called and the response is built
- Respond: The response is returned as a Hash
