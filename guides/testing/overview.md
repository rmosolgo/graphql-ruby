# Overview

So, you've spiked a GraphQL API, and now you're ready to tighten things up and add some proper tests. These guides will help you think about how to ensure stability and compatibility for your GraphQL system.

- [Structure testing](/testing/schema_structure) verifies that schema changes are backwards-compatible. This way, you don't break existing clients.
- [Integration testing](/testing/integration_tests) exercises the various behaviors of the GraphQL system, making sure that it returns the right data to the right clients.
- [Testing helpers](/testing/helpers) for running GraphQL fields without writing a whole query
