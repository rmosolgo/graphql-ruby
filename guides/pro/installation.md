---
title: GraphQL::Pro — Installation
---

`GraphQL::Pro` is distributed as a Ruby gem. When you buy `GraphQL::Pro`, you'll receive credentials, which you can register with bundler:

```sh
bundle config gems.graphql.pro #{YOUR_CREDENTIALS}
```

Then, you can add `graphql-pro` to your Gemfile, which a custom `source`:

```ruby
source "https://gems.graphql.pro" do
  gem "graphql-pro"
end
```

Then, install the gem with Bundler:

```sh
bundle install
```

Then, check out some of `GraphQL::Pro`'s features!

## Updates

To update `GraphQL::Pro`, use Bundler:

```sh
bundle update graphql-pro
```

Be sure to check the [changelog](https://github.com/rmosolgo/graphql-ruby/blob/master/CHANGELOG-pro.md) between versions!

## Dependencies

`graphql-pro 1.0.0` requires `graphql ~>1.4`.

## Verifying Integrity

You can verify the integrity of `graphql-pro` by getting its checksum and comparing it to the [published checksums](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/pro/checksums).

First, get the checksum:

```sh
# For example, to get the checksum of graphql-pro 1.0.0:
$ gem fetch graphql-pro -v 1.0.0 --source https://YOUR_KEY@gems.graphql.pro
$ ruby -rdigest/sha2 -e "puts Digest::SHA512.new.hexdigest(File.read('graphql-pro-1.0.0.gem'))"
```

Then, compare it to the corresponding checksum [listed on GitHub](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/pro/checksums). If it the results don't match, then the gem was compromised.
