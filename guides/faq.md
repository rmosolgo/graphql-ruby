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
With GraphQL there is less of a need to include resource URLs to other REST resources, however sometimes you want to use Rails routing to include a URL as one of your fields. A common use case would be to build HTML format URLs to render a link in your React UI. In that case you can add the Rails route helpers to the execution context as shown below.

Example
-------
```ruby
class Types::UserType < Types::BaseObject
  field :profile_url, String, null: false
  def profile_url
    context[:routes].user_url(object)
  end
end

# Add the url helpers to `context`:
MySchema.execute(
  params[:query],
  variables: params[:variables],
  context: {
    routes: Rails.application.routes.url_helpers,
    # ...
  },
)
```
