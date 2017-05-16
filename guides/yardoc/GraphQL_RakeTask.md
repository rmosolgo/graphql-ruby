---
layout: doc_stub
search: true
title: GraphQL::RakeTask
url: http://www.rubydoc.info/gems/graphql/GraphQL/RakeTask
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/RakeTask
---

Class: GraphQL::RakeTask < Object
A rake task for dumping a schema as IDL or JSON. 
By default, schemas are looked up by name as constants using
`schema_name:`. You can provide a `load_schema` function to return
your schema another way. 
`load_context:`, `only:` and `except:` are supported so that you can
keep an eye on how filters affect your schema. 
Examples:
# Dump a Schema to .graphql + .json files
require "graphql/rake_task"
GraphQL::RakeTask.new(schema_name: "MySchema")
# $ rake graphql:schema:dump
# Schema IDL dumped to ./schema.graphql
# Schema JSON dumped to ./schema.json
# Invoking the task from Ruby
require "rake"
Rake::Task["graphql:schema:dump"].invoke
Includes:
Rake::DSL
Instance methods:
define_task, idl_path, initialize, json_path, rake_namespace,
write_outfile

