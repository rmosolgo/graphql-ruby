# C-based Parser

GraphQL-Ruby includes a plain-Ruby parser, but a faster parser is available as a C extension. To use it, add the [`graphql-c_parser` gem](https://rubygems.org/gems/graphql-c_parser) to your project, for example:

```ruby
bundle add graphql-c_parser
```

When `graphql-c_parser` is `require`d by your app, the C-based parser is installed as the default parser (as [GraphQL.default_parser](rdoc-ref:GraphQL.default_parser)). Bundler requires the library automatically, but you can also require it manually:

```ruby
require "graphql/c_parser"
```

This alternative parser is faster and uses less memory.

The library also adds `GraphQL.scan_with_c` and `GraphQL.parse_with_c` for calling the C-based parser directly.
