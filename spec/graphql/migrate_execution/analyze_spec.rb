# frozen_string_literal: true
require "spec_helper"
require "graphql/migrate_execution"
describe "Analyze Action" do
  it "produces an analysis message" do
    path = "spec/graphql/migrate_execution/fixtures/product.rb"
    source = File.read(path)
    message = GraphQL::MigrateExecution::Analyze.new(path, source).run
    expected_msg = <<~TXT.chomp
Found 9 field definitions:

Implicit (1):
  - Product.title   (nil -> nil) @ spec/graphql/migrate_execution/fixtures/product.rb:4

DoNothing (3):
  - Product.description   (:object_direct_method -> :long_description) @ spec/graphql/migrate_execution/fixtures/product.rb:5
  - Product.brand         (:hash_key -> "brand") @ spec/graphql/migrate_execution/fixtures/product.rb:20
  - Product.diggable      (:dig -> ["key1", "key2"]) @ spec/graphql/migrate_execution/fixtures/product.rb:34

ResolveEach (2):
  - Product.price_in_cents      (:type_instance_method -> :price) @ spec/graphql/migrate_execution/fixtures/product.rb:6
  - Product.viewer_can_afford   (:type_instance_method -> :viewer_can_afford) @ spec/graphql/migrate_execution/fixtures/product.rb:14

ResolveStatic (2):
  - Product.trending   (:type_instance_method -> :trending) @ spec/graphql/migrate_execution/fixtures/product.rb:22
  - Product.on_sale    (:type_instance_method -> :is_on_sale) @ spec/graphql/migrate_execution/fixtures/product.rb:28

NotImplemented (1):
  - Product.resolver_field   (:resolver -> "Resolvers::SomeResolver") @ spec/graphql/migrate_execution/fixtures/product.rb:35
    TXT
    assert_equal expected_msg, message
  end

  it "produces an analysis message on migrated files" do
    path = "spec/graphql/migrate_execution/fixtures/product.migrated.rb"
    source = File.read(path)
    message = GraphQL::MigrateExecution::Analyze.new(path, source).run
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
    message = GraphQL::MigrateExecution::Analyze.new(path, source).run
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
end
