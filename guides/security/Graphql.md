---
layout: guide
doc_stub: false
search: true
section: Security
title: GraphQL layer
desc: GraphQL sepecific rules
index: 1
---

Graphql is a powerful tool for building APIs. It allows the user a lot of flexibility in how they query the data. However, this flexibility can also lead to security vulnerabilities, allowing very complex queries to be executed.

This guide will help you to secure your application before it goes live.

Securing an application is a very broad topic, to be secure, all the layers of the application need to be secure. This guide will focus on the GraphQL and HTTP layers, but it is important to keep in mind that the security of the application is only as strong as its weakest link.

## GET Method

The HTTP GET method will attach a user's browser cookies automatically. This data can be used to create requests to impersonate the user while navigating external websites. To ensure security, it is advised to disable the GET method and configure the Cross-Origin Resource Sharing (CORS) policy of the server accordingly.

## Json content type

The expected Content-Type for GraphQL requests is application/json. To reduce the risk of Cross-Site Request Forgery (CSRF) attacks, it is recommended to disable other Content-Types.

Combined to the GET method, this can be used to create a CSRF attack. The attacker can create a link that will send a request to the GraphQL endpoint with the user's cookies. The user will be tricked into clicking on the link, and the request will be executed.

## Tenant isolation

Tenant isolation is a very important concept in GraphQL. It is important to ensure that a user can only access the data that belongs to them.

As this is deeply related to business logic (cf. {% internal_link "authorization documentation page", "/authorization/overview.html" %}), it is not possible to provide a generic solution. However, there are some general rules that can be followed:

- Token generation must be properly implemented and well tested.
- The token must be stored in a secure way:
  - In a cookie you may look at the [HttpOnly flag](https://owasp.org/www-community/HttpOnly)
  - In a header you want to enforce HTTPS only
- Be careful with third party application as they may not be able to provide the same level of security as your application (asses their security).
- Test your application with a security scanner.

Read more about this topic in the [escape's access control in multi-tenant GraphQL applications blog post](https://escape.tech/blog/access-control-in-multi-tenant-graphql-applications/).

## Rate limiting

Rate limiting in graphql is a bit more complicated than in REST. The reason for this is that the user can specify the amount of data they want to receive. This means that a single request can be very large or very small. To prevent a single user from flooding the server with requests, it is advised to limit the amount of requests a user can make in a given time period.

But as the only endpoint is the graphql endpoint, the classical method (rate limiting at gateway level) is possible but not sufficient. GraphQL allows also the user to batch some queries in a single request. This means that a single request can contain multiple queries and mutations. This can be used to bruteforce passwords.

For example the following request will be detected as a single request by the rate limiter, but mutliples at the application level:

```graphql
mutation { login(username: "admin", password: "admin") }
mutation { login(username: "admin", password: "123456") }
mutation { login(username: "admin", password: "qwerty") }
```

For more information about how to handle query batching, see the {% internal_link "multiplex documentation page", "/queries/multiplex.html" %}.

## Depth limiting

In graphql, the user can specify the amount of data they want to receive. This means that a single request can be very large or very small. To prevent a single user from flooding the server with requests, it is advised to limit the amount of data a user can request in a single request.

This request can be allowed:

```graphql
query {
  user {
    name
    friends {
      name
      friends {
        name
        friends {
          name
          friends { ... }
        }
      }
    }
  }
}
```

Here with a depth of 20 the query will very likely ask your resolver to dump the whole database.

To prevent that, you want to implement the {% internal_link "depth limiting", "queries/complexity_and_depth.html#prevent-deeply-nested-queries" %} at schema level.
