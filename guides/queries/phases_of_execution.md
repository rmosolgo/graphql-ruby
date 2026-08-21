# Phases of Execution

When GraphQL receives a query string, it goes through these steps:

- Tokenize: [GraphQL::Language::Lexer](rdoc-ref:GraphQL::Language::Lexer) splits the string into a stream of tokens
- Parse: [GraphQL::Language::Parser](rdoc-ref:GraphQL::Language::Parser) builds an abstract syntax tree (AST) out of the stream of tokens
- Validate: [GraphQL::StaticValidation::Validator](rdoc-ref:GraphQL::StaticValidation::Validator) validates the incoming AST as a valid query for the schema
- Analyze: If there are any query analyzers, they are run with [GraphQL::Analysis.analyze_query](rdoc-ref:GraphQL::Analysis.analyze_query)
- Execute: The query is traversed, `resolve` functions are called and the response is built
- Respond: The response is returned as a [GraphQL::Query::Result](rdoc-ref:GraphQL::Query::Result)
