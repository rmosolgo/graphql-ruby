---
layout: guide
doc_stub: false
search: true
section: Security
title: Security testing
desc: Assessing the security of your application
index: 3
---

At this point you must have a good understanding of how to secure your application. However, it is important to keep in mind that security is a never ending process. It is important to keep your application up to date and to test it regularly.

As the application is continuously evolving, it is important to beeing kept up to date with the latest security issues.

A good way to do this is to use a DAST (Dynamic Application Security Testing) tool. This tool will automatically scan your application and report any security issues it finds.

Here is a list of different DAST tools that you can use :

## GraphQL security

You can use [graphql.security](https://graphql.security), a free GraphQL security testing tool that quickly identifies the most common vulnerabilities in your application.

## Escape

Another option is [Escape](https://escape.tech), a GraphQL security SaaS platform that includes an automated pentest tool.

This can be integrated into your CI/CD pipeline, such as Github Actions or Gitlab CIs. The security notifications will be automatically communicated to your CI/CD platform, allowing you to address any issues promptly.
