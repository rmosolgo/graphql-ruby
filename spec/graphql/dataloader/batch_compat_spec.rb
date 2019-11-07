# frozen_string_literal: true
#
# GraphQL::Dataloader is basically ripped off from Shopify/graphql-batch,
# so make sure that it can do everything that graphql-batch can do.
#
# Adapted from https://github.com/Shopify/graphql-batch/blob/master/test/graphql_test.rb
require 'spec_helper'

class GraphQLDataloaderBatchCompatTest < Minitest::Test
  class QueryNotifier
    class << self
      attr_accessor :subscriber

      def call(query)
        subscriber && subscriber.call(query)
      end
    end
  end

  module ModelClassMethods
    attr_accessor :fixtures, :has_manys

    def model_name
      name.split("::").last
    end

    def first(count)
      QueryNotifier.call("#{model_name}?limit=#{count}")
      fixtures.values.first(count).map(&:dup)
    end

    def find(ids)
      ids = Array(ids)
      QueryNotifier.call("#{model_name}/#{ids.join(',')}")
      ids.map{ |id| fixtures[id] }.compact.map(&:dup)
    end

    def preload_association(owners, association)
      association_reflection = reflect_on_association(association)
      foreign_key = association_reflection[:foreign_key]
      scope = association_reflection[:scope]
      rows = association_reflection[:model].fixtures.values
      owner_ids = owners.map(&:id).to_set

      QueryNotifier.call("#{model_name}/#{owners.map(&:id).join(',')}/#{association}")
      records = rows.select{ |row|
        owner_ids.include?(row.public_send(foreign_key)) && scope.call(row)
      }

      records_by_key = records.group_by(&foreign_key)
      owners.each do |owner|
        owner.public_send("#{association}=", records_by_key[owner.id] || [])
      end
      nil
    end

    def has_many(association_name, model:, foreign_key:, scope: ->(row){ true })
      self.has_manys ||= {}
      has_manys[association_name] = { model: model, foreign_key: foreign_key, scope: scope }
      attr_accessor(association_name)
    end

    def reflect_on_association(association)
      has_manys.fetch(association)
    end
  end

  Image = Struct.new(:id, :owner_type, :owner_id, :filename) do
    extend ModelClassMethods
  end

  ProductVariant = Struct.new(:id, :product_id, :title) do
    extend ModelClassMethods
    has_many :images, model: Image, foreign_key: :owner_id, scope: ->(row) { row.owner_type == 'ProductVariant' }
  end

  Product = Struct.new(:id, :title, :image_id) do
    extend ModelClassMethods
    has_many :variants, model: ProductVariant, foreign_key: :product_id
  end

  Product.fixtures = [
    Product.new(1, "Shirt", 1),
    Product.new(2, "Pants", 2),
    Product.new(3, "Sweater", 3),
  ].each_with_object({}){ |p, h| h[p.id] = p }

  ProductVariant.fixtures = [
    ProductVariant.new(1, 1, "Red"),
    ProductVariant.new(2, 1, "Blue"),
    ProductVariant.new(4, 2, "Small"),
    ProductVariant.new(5, 2, "Medium"),
    ProductVariant.new(6, 2, "Large"),
    ProductVariant.new(7, 3, "Default"),
  ].each_with_object({}){ |p, h| h[p.id] = p }

  Image.fixtures = [
    Image.new(1, 'Product', 1, "shirt.jpg"),
    Image.new(2, 'Product', 2, "pants.jpg"),
    Image.new(3, 'Product', 3, "sweater.jpg"),
    Image.new(4, 'ProductVariant', 1, "red-shirt.jpg"),
    Image.new(5, 'ProductVariant', 2, "blue-shirt.jpg"),
    Image.new(6, 'ProductVariant', 3, "small-pants.jpg"),
  ].each_with_object({}){ |p, h| h[p.id] = p }

  class RecordLoader < GraphQL::Dataloader::Loader
    def initialize(ctx, model)
      super
      @model = model
    end

    def load(id)
      super(Integer(id))
    end

    def perform(ids)
      @model.find(ids).each { |record| fulfill(record.id, record) }
      ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
    end
  end

  class AssociationLoader < GraphQL::Dataloader::Loader
    def initialize(ctx, model, association)
      super
      @model = model
      @association = association
    end

    def perform(owners)
      @model.preload_association(owners, @association)
      owners.each { |owner| fulfill(owner, owner.public_send(@association)) }
    end
  end

  class CounterLoader < GraphQL::Dataloader::Loader
    def cache_key(counter_array)
      counter_array.object_id
    end

    def perform(keys)
      keys.each { |counter_array| fulfill(counter_array, counter_array[0]) }
    end
  end

  class NilLoader < GraphQL::Dataloader::Loader
    def self.load(ctx)
      self.for(ctx, nil).load(nil)
    end

    def perform(nils)
      nils.each { |key| fulfill(nil, nil) }
    end
  end

  class ImageType < GraphQL::Schema::Object
    field :id, ID, null: false
    field :filename, String, null: false
  end

  class ProductVariantType < GraphQL::Schema::Object
    field :id, ID, null: false
    field :title, String, null: false
    field :image_ids, [ID, null: true], null: false

    def image_ids
      AssociationLoader.for(context, ProductVariant, :images).load(object).then do |images|
        images.map(&:id)
      end
    end

    field :product, GraphQL::Schema::LateBoundType.new('Product'), null: false

    def product
      RecordLoader.for(context, Product).load(object.product_id)
    end
  end

  class ProductType < GraphQL::Schema::Object
    field :id, ID, null: false
    field :title, String, null: false
    field :images, [ImageType], null: true

    def images
      product_image_query = RecordLoader.for(context, Image).load(object.image_id)
      variant_images_query = AssociationLoader.for(context, Product, :variants).load(object).then do |variants|
        variant_image_queries = variants.map do |variant|
          AssociationLoader.for(context, ProductVariant, :images).load(variant)
        end
        GraphQL::Execution::Lazy.all(variant_image_queries).then(&:flatten)
      end
      GraphQL::Execution::Lazy.all([product_image_query, variant_images_query]).then do
        [product_image_query.value] + variant_images_query.value
      end
    end

    field :non_null_but_raises, String, null: false

    def non_null_but_raises
      raise GraphQL::ExecutionError, 'Error'
    end

    field :variants, [ProductVariantType], null: true

    def variants
      AssociationLoader.for(context, Product, :variants).load(object)
    end

    field :variants_count, Int, null: true

    def variants_count
      query = AssociationLoader.for(context, Product, :variants).load(object)
      GraphQL::Execution::Lazy.all([query]).then { query.value.size }
    end
  end

  class QueryType < GraphQL::Schema::Object
    field :constant, String, null: false

    def constant
      "constant value"
    end

    field :load_execution_error, String, null: true

    def load_execution_error
      RecordLoader.for(context, Product).load(1).then do |product|
        raise GraphQL::ExecutionError, "test error message"
      end
    end

    field :non_null_but_raises, ProductType, null: false

    def non_null_but_raises
      raise GraphQL::ExecutionError, 'Error'
    end

    field :non_null_but_promise_raises, String, null: false

    def non_null_but_promise_raises
      NilLoader.load(context).then do
        raise GraphQL::ExecutionError, 'Error'
      end
    end

    field :product, ProductType, null: true do
      argument :id, ID, required: true
    end

    def product(id:)
      RecordLoader.for(context, Product).load(id)
    end

    field :products, [ProductType], null: true do
      argument :first, Int, required: true
    end

    def products(first:)
      Product.first(first)
    end

    field :product_variants_count, Int, null: true do
      argument :id, ID, required: true
    end

    def product_variants_count(id:)
      RecordLoader.for(context, Product).load(id).then do |product|
        AssociationLoader.for(context, Product, :variants).load(product).then(&:size)
      end
    end
  end

  class CounterType < GraphQL::Schema::Object
    field :value, Int, null: false

    def value
      object
    end

    field :load_value, Int, null: false

    def load_value
      CounterLoader.load(context, context[:counter])
    end
  end

  class IncrementCounterMutation < GraphQL::Schema::Mutation
    null false
    payload_type CounterType

    def resolve
      context[:counter][0] += 1
      CounterLoader.load(context, context[:counter])
    end
  end

  class CounterLoaderMutation < GraphQL::Schema::Mutation
    null false
    payload_type Int

    def resolve
      CounterLoader.load(context, context[:counter])
    end
  end

  class NoOpMutation < GraphQL::Schema::Mutation
    null false
    payload_type QueryType

    def resolve
      Hash.new
    end
  end

  class MutationType < GraphQL::Schema::Object
    field :increment_counter, mutation: IncrementCounterMutation
    field :counter_loader, mutation: CounterLoaderMutation
    field :no_op, mutation: NoOpMutation
  end

  class Schema < GraphQL::Schema
    query QueryType
    mutation MutationType
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::Dataloader
  end

  attr_reader :queries

  def setup
    @queries = []
    QueryNotifier.subscriber = ->(query) { @queries << query }
  end

  def teardown
    QueryNotifier.subscriber = nil
  end

  def test_no_queries
    query_string = '{ constant }'
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "constant" => "constant value"
      }
    }
    assert_equal expected, result
    assert_equal [], queries
  end

  def test_single_query
    query_string = <<-GRAPHQL
      {
        product(id: "1") {
          id
          title
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "product" => {
          "id" => "1",
          "title" => "Shirt",
        }
      }
    }
    assert_equal expected, result
    assert_equal ["Product/1"], queries
  end

  def test_batched_find_by_id
    query_string = <<-GRAPHQL
      {
        product1: product(id: "1") { id, title }
        product2: product(id: "2") { id, title }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "product1" => { "id" => "1", "title" => "Shirt" },
        "product2" => { "id" => "2", "title" => "Pants" },
      }
    }
    assert_equal expected, result
    assert_equal ["Product/1,2"], queries
  end

  def test_record_missing
    query_string = <<-GRAPHQL
      {
        product(id: "123") {
          id
          title
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = { "data" => { "product" => nil } }
    assert_equal expected, result
    assert_equal ["Product/123"], queries
  end

  def test_non_null_field_that_raises_on_nullable_parent
    query_string = <<-GRAPHQL
      {
        product(id: "1") {
          id
          nonNullButRaises
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = { 'data' => { 'product' => nil }, 'errors' => [{ 'message' => 'Error', 'locations' => [{ 'line' => 4, 'column' => 11 }], 'path' => ['product', 'nonNullButRaises'] }] }
    assert_equal expected, result
  end

  def test_non_null_field_that_raises_on_query_root
    query_string = <<-GRAPHQL
      {
        nonNullButRaises {
          id
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = { 'data' => nil, 'errors' => [{ 'message' => 'Error', 'locations' => [{ 'line' => 2, 'column' => 9 }], 'path' => ['nonNullButRaises'] }] }
    assert_equal expected, result
  end

  def test_non_null_field_promise_raises
    result = Schema.execute('{ nonNullButPromiseRaises }')
    expected = { 'data' => nil, 'errors' => [{ 'message' => 'Error', 'locations' => [{ 'line' => 1, 'column' => 3 }], 'path' => ['nonNullButPromiseRaises'] }] }
    assert_equal expected, result
  end

  def test_batched_association_preload
    query_string = <<-GRAPHQL
      {
        products(first: 2) {
          id
          title
          variants {
            id
            title
          }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "products" => [
          {
            "id" => "1",
            "title" => "Shirt",
            "variants" => [
              { "id" => "1", "title" => "Red" },
              { "id" => "2", "title" => "Blue" },
            ],
          },
          {
            "id" => "2",
            "title" => "Pants",
            "variants" => [
              { "id" => "4", "title" => "Small" },
              { "id" => "5", "title" => "Medium" },
              { "id" => "6", "title" => "Large" },
            ],
          }
        ]
      }
    }
    assert_equal expected, result
    assert_equal ["Product?limit=2", "Product/1,2/variants"], queries
  end

  def test_query_group_with_single_query
    query_string = <<-GRAPHQL
      {
        products(first: 2) {
          id
          title
          variantsCount
          variants {
            id
            title
          }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "products" => [
          {
            "id" => "1",
            "title" => "Shirt",
            "variantsCount" => 2,
            "variants" => [
              { "id" => "1", "title" => "Red" },
              { "id" => "2", "title" => "Blue" },
            ],
          },
          {
            "id" => "2",
            "title" => "Pants",
            "variantsCount" => 3,
            "variants" => [
              { "id" => "4", "title" => "Small" },
              { "id" => "5", "title" => "Medium" },
              { "id" => "6", "title" => "Large" },
            ],
          }
        ]
      }
    }
    assert_equal expected, result
    assert_equal ["Product?limit=2", "Product/1,2/variants"], queries
  end

  def test_sub_queries
    query_string = <<-GRAPHQL
      {
        productVariantsCount(id: "2")
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "productVariantsCount" => 3
      }
    }
    assert_equal expected, result
    assert_equal ["Product/2", "Product/2/variants"], queries
  end

  def test_query_group_with_sub_queries
    query_string = <<-GRAPHQL
      {
        product(id: "1") {
          images { id, filename }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "product" => {
          "images" => [
            { "id" => "1", "filename" => "shirt.jpg" },
            { "id" => "4", "filename" => "red-shirt.jpg" },
            { "id" => "5", "filename" => "blue-shirt.jpg" },
          ]
        }
      }
    }
    assert_equal expected, result
    assert_equal ["Product/1", "Image/1", "Product/1/variants", "ProductVariant/1,2/images"], queries
  end

  def test_load_list_of_objects_with_loaded_field
    query_string = <<-GRAPHQL
      {
        products(first: 2) {
          id
          variants {
            id
            imageIds
          }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "products" => [
          {
            "id" => "1",
            "variants" => [
              { "id" => "1", "imageIds" => ["4"] },
              { "id" => "2", "imageIds" => ["5"] },
            ],
          },
          {
            "id" => "2",
            "variants" => [
              { "id" => "4", "imageIds" => [] },
              { "id" => "5", "imageIds" => [] },
              { "id" => "6", "imageIds" => [] },
            ],
          }
        ]
      }
    }
    assert_equal expected, result
    assert_equal ["Product?limit=2", "Product/1,2/variants", "ProductVariant/1,2,4,5,6/images"], queries
  end

  def test_loader_reused_after_loading
    query_string = <<-GRAPHQL
      {
        product(id: "2") {
          variants {
            id
            product {
              id
              title
            }
          }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "product" => {
          "variants" => [
            { "id" => "4", "product" => { "id" => "2", "title" => "Pants" } },
            { "id" => "5", "product" => { "id" => "2", "title" => "Pants" } },
            { "id" => "6", "product" => { "id" => "2", "title" => "Pants" } },
          ],
        }
      }
    }
    assert_equal expected, result
    assert_equal ["Product/2", "Product/2/variants"], queries
  end

  def test_load_error
    query_string = <<-GRAPHQL
      {
        constant
        loadExecutionError
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => { "constant"=>"constant value", "loadExecutionError" => nil },
      "errors" => [{ "message" => "test error message", "locations"=>[{"line"=>3, "column"=>9}], "path" => ["loadExecutionError"] }],
    }
    assert_equal expected, result
  end

  def test_mutation_execution
    query_string = <<-GRAPHQL
      mutation {
        count1: counterLoader
        incr1: incrementCounter { value, loadValue }
        count2: counterLoader
        incr2: incrementCounter { value, loadValue }
      }
    GRAPHQL
    result = Schema.execute(query_string, context: { counter: [0] })
    expected = {
      "data" => {
        "count1" => 0,
        "incr1" => { "value" => 1, "loadValue" => 1 },
        "count2" => 1,
        "incr2" => { "value" => 2, "loadValue" => 2 },
      }
    }
    assert_equal expected, result
  end

  def test_mutation_batch_subselection_execution
    query_string = <<-GRAPHQL
      mutation {
        mutation1: noOp {
          product1: product(id: "1") { id, title }
          product2: product(id: "2") { id, title }
        }
        mutation2: noOp {
          product1: product(id: "2") { id, title }
          product2: product(id: "3") { id, title }
        }
      }
    GRAPHQL
    result = Schema.execute(query_string)
    expected = {
      "data" => {
        "mutation1" => {
          "product1" => { "id" => "1", "title" => "Shirt" },
          "product2" => { "id" => "2", "title" => "Pants" },
        },
        "mutation2" => {
          "product1" => { "id" => "2", "title" => "Pants" },
          "product2" => { "id" => "3", "title" => "Sweater" },
        }
      }
    }
    assert_equal expected, result
    assert_equal ["Product/1,2", "Product/2,3"], queries
  end
end
