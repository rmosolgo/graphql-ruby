---
layout: guide
doc_stub: false
search: true
title: FAQ
other: true
desc: How to do common tasks
---


Returning Route URLs
====================
With graphql there is less of a need to include resource URLs to other REST resources, however sometimes you want to use Rails routing to include a URL as one of your fields. A common use case would be to build HTML format URLs to render a link in your React UI. In that case you can add the Rails route helpers to the execution context as shown below.

Example
-------
```ruby
Types::UserType = GraphQL::ObjectType.define do
  field :profile_url, types.String do
      description 'web show url'
      resolve -> (user, args, ctx) { ctx[:routes].user_url(user) }
  end
end

MySchema.execute(
  params[:query],
  variables: params[:variables],
  context: { routes: Rails.application.routes.url_helpers },
)
```