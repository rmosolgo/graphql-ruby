---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - OperationStore
title: Access Control
desc: Manage authentication & visibility for your OperationStore server.
index: 4
pro: true
---

There are two considerations for incoming `sync` requests:

- __Authentication__: is this request coming from a legitimate source?
- __Authorization__: does this source have permission to save these queries?

## Authentication

When you [add a client]({{ site.base_url }}/operation_store/client_workflow#add-a-client), you also associate a _secret_ with that client. You can use the default or provide your own and you can update a client secret at any time. By updating a secret, old secrets become invalid.

This secret is used to add an authorization header, generated with HMAC-SHA256. With this header, the server can assert:

- The request came from an authorized client
- The request was not corrupted in transit

For more info about HMAC, see [Wikipedia](https://en.wikipedia.org/wiki/Hash-based_message_authentication_code) or Ruby's [OpenSSL::HMAC](https://ruby-doc.org/stdlib-2.4.0/libdoc/openssl/rdoc/OpenSSL/HMAC.html) support.

The Authorization header takes the form:

```ruby
"GraphQL::Pro #{client_name} #{hmac}"
```

{% internal_link "graphql-ruby-client", "/javascript_client/sync" %} adds this header to outgoing requests by using the provided `--client` and `--secret` values.

## Authorization

Incoming operations are validated. If you're using `GraphQL::Pro`'s {% internal_link "visibility authorization", "/pro/authorization#visibility-authorization" %}, you must determine whether the current client can _see_ the types and fields which are used in the operation.

You can implement authorization for incoming queries with the `authorize(..., operation_store:)` option, which accepts a {% internal_link "auth strategy class", "/pro/authorization#custom-authorization-strategy" %}, for example:

```ruby
authorize(:pundit, operation_store: OperationStoreStrategy)
# Or:
authorize(MyAuthStrategy, operation_store: OperationStoreStrategy)
```

This strategy class is used _only_ for incoming persisted operations. The strategy class may use `ctx[:current_client_name]`, which is added by the OperationStore.

Here's an example strategy class which allows `"stafftools"` apps to use `view: :admin` fields, but hides those fields from everyone else:

```ruby
class OperationStoreStrategy
  def initialize(ctx)
    @client_name = ctx[:current_client_name]
  end

  # Only stafftools apps can save queries with `:admin` fields
  # Anyone can save queries with `:public` fields.
  def allowed?(gate, _obj)
    case gate.role
    when :admin
      @client_name == "stafftools"
    when :public
      true
    else
      raise "Unexpected auth role: #{gate.role}"
    end
  end
end
```

If you don't specify a strategy, the default is to fail all `view:` checks. This way, private fields are _not_ disclosed via OperationStore requests.
