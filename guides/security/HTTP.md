---
layout: guide
doc_stub: false
search: true
section: Security
title: HTTP layer
desc: Global security settings
index: 2
---

In this part, we will cover any security settings that are not specific to GraphQL but are still important to consider when building a secure application.

There is two types of attacks that you want to mitigate :

- **Attacks on your server** : You want to configure rate limiting and firewall to prevent your server from being overwhelmed an evil user.
- **Attacks on users data** : You also want to configure your server to prevent users data from being stolen or modified.

## Attacks on your server

This part is a big topic and may be linked to your business cases and cloud provider. We will only cover the basics here but if you want to learn more, you can read the [OWASP Top 10](https://owasp.org/www-project-top-ten/) and the [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/).

### Firewall

You may configure a firewall to prevent your server from being overwhelmed by a malicious user.

By definition, a firewall is a component that controls network traffic. It can be implemented as an external application acting as a gateway between your server and the internet or as a software running on your server.

Your cloud provider may have some tools to help you with this. For example, [AWS WAF](https://aws.amazon.com/waf/) or [Google Cloud armor](https://cloud.google.com/armor/docs/cloud-armor-overview).

But it can also be integrated in your application. For example, [ruby on rails has a firewall](https://guides.rubyonrails.org/security.html#firewalls) that can be configured to block requests from specific IP addresses.

### Rate limiting

Rate limiting is a mechanism that allows you to limit the number of requests that can be made to your API. This is useful to prevent your server from being overwhelmed by a malicious user.

As graphql endpoint is the same for all requests (except for subscriptions), your HTTP rate limiting will be applied to all requests. The configured rate will be higher than on a classic REST API because endpoint is fetched mutliples times (login, logout, retrieve data...).

In graphql, you can also batch multiple queries in one request. This is useful to reduce the number of requests made to the server but it can also be used to bypass rate limiting. Read the {% internal_link "Graphql rate limiting", "security/Graphql.html#rate-limiting" %} guide to learn more about this.

## Secure user's data

### CORS

CORS stands for Cross-Origin Resource Sharing. It is a mechanism that allows restricted resources on a web page to be requested from another domain outside the domain from which the first resource was served.

If you don't configure any CORS settings, the default settings will be used. This means that any domain can access your API. This is not recommended for production environments because it allows any website to impersonate the user and make requests to your API.

You may want to configure your CORS settings to only allow your domain : the needed header to set is `Access-Control-Allow-Origin: my.api.example.com`.

## HTTP Strict Transport Security

HTTP Strict Transport Security (HSTS) is a web security policy mechanism that helps to protect websites against protocol downgrade attacks and cookie hijacking. It allows web servers to declare that web browsers (or other complying user agents) should only interact with it using secure HTTPS connections, and never via the insecure HTTP protocol.

## Totally disable HTTP

If there is no use cases where you need to use HTTP, you may want to configure your server to only allow HTTPS connections. It will avoid a mistake from a developer that send some data without encryption.

## X-Frame-Options

X-Frame-Options is a header that can be used to indicate whether or not a browser should be allowed to render a page in a `<frame>`, `<iframe>` or `<object>` . Sites can use this to avoid clickjacking attacks, by ensuring that their content is not embedded into other sites.

By default your api allows your content to be embedded in any website. You may want to configure this header to only allow your domain : `X-Frame-Options: SAMEORIGIN`.
