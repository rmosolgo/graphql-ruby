# Documentation maintenance

GraphQL-Ruby documentation is generated with RDoc and the Aliki generator. API comments live beside the Ruby code, while tutorials and cross-cutting explanations remain Markdown pages in `guides/`.

Install the optional documentation dependencies and build a local site with:

```sh
BUNDLE_WITH=docs bundle install
bundle exec rake docs:build
```

The generated site is written to `tmp/rdoc-site`. To preview it, run `bundle exec rake docs:rdoc:serve` and open `http://127.0.0.1:8808`.

Run the documentation checks before submitting a change:

```sh
bundle exec rake docs:check
bundle exec rake docs:build_twice
```

Use `rdoc-ref:GraphQL::Schema#execute` (or the corresponding class-method form) for links from comments and guides. Add a short API comment when a public method is missing from the generated index. Dynamic methods should use RDoc directives such as `:method:` and `:call-seq:` rather than introducing new YARD tags.

Use a fenced `graphql` block for GraphQL examples:

````markdown
```graphql
query Viewer {
  viewer { id }
}
```
````

When a page or API moves, add an entry to `docs/redirects.yml` so the old URL remains usable. Run `bundle exec ruby tool/docs/link_checker.rb --root tmp/rdoc-site --strict` to verify the redirect and its fragment.

Release builds use `bundle exec rake "docs:rdoc:build_version[VERSION]"` to generate a versioned API site under `tmp/rdoc-api/VERSION`. The publish workflow copies that directory into `gh-pages/api-doc/VERSION` without removing older versions.
