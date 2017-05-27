---
layout: doc_stub
search: true
title: GraphQL::Schema::Warden
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/Warden
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/Warden
---

Class: GraphQL::Schema::Warden < Object
This class is part of a private API.
Restrict access to a GraphQL::Schema with a user-defined mask. 
The mask is object that responds to `#visible?(schema_member)`. 
When validating and executing a query, all access to schema members
should go through a warden. If you access the schema directly, you
may show a client something that it shouldn't be allowed to see. 
Masks can be provided in Schema#execute (or Query#initialize) with
the `mask:` keyword. 
Examples:
# Hidding private fields
private_members = -> (member, ctx) { member.metadata[:private] }
result = Schema.execute(query_string, except: private_members)
# Custom mask implementation
# It must respond to `#call(member)`.
class MissingRequiredFlags
def initialize(user)
@user = user
end
# Return `false` if any required flags are missing
def call(member, ctx)
member.metadata[:required_flags].any? do |flag|
!@user.has_flag?(flag)
end
end
end
# Then, use the custom filter in query:
missing_required_flags = MissingRequiredFlags.new(current_user)
# This query can only access members which match the user's flags
result = Schema.execute(query_string, except: missing_required_flags)
Instance methods:
arguments, directives, enum_values, fields, get_field, get_type,
initialize, interfaces, possible_types, read_through,
root_type_for_operation, types, visible?, visible_field?

