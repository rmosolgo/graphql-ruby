# frozen_string_literal: true
require "spec_helper"
require "graphql/migrate_execution"
require "ostruct"

describe "Analyze Action" do
  it "produces an analysis message" do
    path = "spec/graphql/migrate_execution/fixtures/product.rb"
    source = File.read(path)
    message = GraphQL::MigrateExecution::Analyze.new(OpenStruct.new, path, source).run
    expected_msg = <<~TXT.chomp
Found 9 field definitions:

Implicit (1):
  These fields use GraphQL-Ruby's default, implicit resolution behavior. It's changing in the future, please audit these fields and choose a migration strategy:

    - `--preserve-implicit`: Don't add any new configuration; use GraphQL-Ruby's future direct method send behavior (ie `object.public_send(field_name, **arguments)`)
    - `--shim-implicit`: Add a method to preserve GraphQL-Ruby's previous dynamic implicit behavior (ie, checking for `respond_to?` and `key?`)

  - Product.title   (nil -> nil) @ spec/graphql/migrate_execution/fixtures/product.rb:4

DoNothing (3):
  These field definitions are already future-compatible. No migration is required.

  - Product.description   (:object_direct_method -> :long_description) @ spec/graphql/migrate_execution/fixtures/product.rb:5
  - Product.brand         (:hash_key -> "brand") @ spec/graphql/migrate_execution/fixtures/product.rb:20
  - Product.diggable      (:dig -> ["key1", "key2"]) @ spec/graphql/migrate_execution/fixtures/product.rb:34

ResolveEach (2):
  These can be converted with `resolve_each:`. Dataloader was not detected in these resolver methods.

  - Product.price_in_cents      (:type_instance_method -> :price) @ spec/graphql/migrate_execution/fixtures/product.rb:6
  - Product.viewer_can_afford   (:type_instance_method -> :viewer_can_afford) @ spec/graphql/migrate_execution/fixtures/product.rb:14

ResolveStatic (2):
  These can be converted with `resolve_static:`. Dataloader was not detected in these resolver methods.

  - Product.trending   (:type_instance_method -> :trending) @ spec/graphql/migrate_execution/fixtures/product.rb:22
  - Product.on_sale    (:type_instance_method -> :is_on_sale) @ spec/graphql/migrate_execution/fixtures/product.rb:28

NotImplemented (1):
  GraphQL-Ruby doesn't have a migration strategy for these fields. Automated migration may be possible -- please open an issue on GitHub with the source for these fields to investigate.

  - Product.resolver_field   (:resolver -> "Resolvers::SomeResolver") @ spec/graphql/migrate_execution/fixtures/product.rb:35
    TXT
    assert_equal expected_msg, message
  end

  it "produces an analysis message on migrated files" do
    path = "spec/graphql/migrate_execution/fixtures/product.migrated.rb"
    source = File.read(path)
    message = GraphQL::MigrateExecution::Analyze.new(OpenStruct.new(skip_description: true), path, source).run
    expected_msg = <<~TXT.chomp
Found 9 field definitions:

Implicit (1):
  - Product.title   (nil -> nil) @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:4

DoNothing (3):
  - Product.description   (:object_direct_method -> :long_description) @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:5
  - Product.brand         (:hash_key -> "brand") @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:28
  - Product.diggable      (:dig -> ["key1", "key2"]) @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:50

ResolveEach (2):
  - Product.price_in_cents      (:already_migrated -> {resolve_each: :price}) @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:6
  - Product.viewer_can_afford   (:already_migrated -> {resolve_each: true}) @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:18

ResolveStatic (2):
  - Product.trending   (:already_migrated -> {resolve_static: true}) @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:30
  - Product.on_sale    (:already_migrated -> {resolve_static: :is_on_sale}) @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:40

NotImplemented (1):
  - Product.resolver_field   (:resolver -> "Resolvers::SomeResolver") @ spec/graphql/migrate_execution/fixtures/product.migrated.rb:51
    TXT
    assert_equal expected_msg, message
  end

  it "produces an analysis message on future files" do
    path = "spec/graphql/migrate_execution/fixtures/product.future.rb"
    source = File.read(path)
    message = GraphQL::MigrateExecution::Analyze.new(OpenStruct.new(skip_description: true), path, source).run
    expected_msg = <<~TXT.chomp
Found 9 field definitions:

Implicit (1):
  - Product.title   (nil -> nil) @ spec/graphql/migrate_execution/fixtures/product.future.rb:4

DoNothing (3):
  - Product.description   (:object_direct_method -> :long_description) @ spec/graphql/migrate_execution/fixtures/product.future.rb:5
  - Product.brand         (:hash_key -> "brand") @ spec/graphql/migrate_execution/fixtures/product.future.rb:20
  - Product.diggable      (:dig -> ["key1", "key2"]) @ spec/graphql/migrate_execution/fixtures/product.future.rb:34

ResolveEach (2):
  - Product.price_in_cents      (:already_migrated -> {resolve_each: :price}) @ spec/graphql/migrate_execution/fixtures/product.future.rb:6
  - Product.viewer_can_afford   (:already_migrated -> {resolve_each: true}) @ spec/graphql/migrate_execution/fixtures/product.future.rb:14

ResolveStatic (2):
  - Product.trending   (:already_migrated -> {resolve_static: true}) @ spec/graphql/migrate_execution/fixtures/product.future.rb:22
  - Product.on_sale    (:already_migrated -> {resolve_static: :is_on_sale}) @ spec/graphql/migrate_execution/fixtures/product.future.rb:28

NotImplemented (1):
  - Product.resolver_field   (:resolver -> "Resolvers::SomeResolver") @ spec/graphql/migrate_execution/fixtures/product.future.rb:35
    TXT
    assert_equal(expected_msg, message)
  end


  it "analyzes dataloader usage" do
    path = "spec/graphql/migrate_execution/fixtures/dataload.rb"
    source = File.read(path)
    message = GraphQL::MigrateExecution::Analyze.new(OpenStruct.new, path, source).run
    expected_msg = <<~TXT.chomp
Found 6 field definitions:

DataloaderAssociation (1):
  These fields can use a `dataload_association:` option.

  - Something.dataload_assoc   (:type_instance_method -> :dataload_assoc) @ spec/graphql/migrate_execution/fixtures/dataload.rb:6

DataloadAll (2):
  These fields can use a `dataload:` option.

  - Something.dataload_object_1   (:type_instance_method -> :dataload_object_1) @ spec/graphql/migrate_execution/fixtures/dataload.rb:12
  - Something.dataload_object_2   (:type_instance_method -> :dataload_object_2) @ spec/graphql/migrate_execution/fixtures/dataload.rb:18

DataloaderBatch (2):
  These fields can be rewritten to dataload in a `resolve_batch:` method.

  - Something.dataload_rec     (:type_instance_method -> :dataload_rec) @ spec/graphql/migrate_execution/fixtures/dataload.rb:24
  - Something.dataload_rec_2   (:type_instance_method -> :dataload_rec_2) @ spec/graphql/migrate_execution/fixtures/dataload.rb:30

DataloaderManual (1):
  These fields use Dataloader in a way that can't be automatically migrated. You'll have to migrate them manually.
  If you have a lot of these, consider opening up an issue on GraphQL-Ruby -- maybe we can find a way to programmatically support them.

  - Something.dataload_complicated   (:type_instance_method -> :dataload_complicated) @ spec/graphql/migrate_execution/fixtures/dataload.rb:36
    TXT
    assert_equal(expected_msg, message)
  end
end
