# frozen_string_literal: true

require "spec_helper"
require "graphql/language/cache"
require "pathname"
require "tmpdir"

class GraphQLLanguageCacheGadget
  class << self
    attr_accessor :called

    def marshal_dump
      []
    end

    def marshal_load(_data)
      self.called = true
    end
  end
end

describe GraphQL::Language::Cache do
  def with_cache
    Dir.mktmpdir do |dir|
      source = Pathname(dir).join("schema.graphql")
      cache_path = Pathname(dir).join("cache")
      source.write("type Query { hello: String }\n")
      yield source, cache_path, GraphQL::Language::Cache.new(cache_path)
    end
  end

  it "reuses a verified cache entry" do
    with_cache do |source, _cache_path, cache|
      calls = 0
      assert_equal :parsed, cache.fetch(source.to_s) { calls += 1; :parsed }
      assert_equal :parsed, cache.fetch(source.to_s) { flunk("cache was not reused") }
      assert_equal 1, calls
    end
  end

  it "reuses a cache entry across cache instances with the same secret" do
    with_cache do |source, cache_path, _cache|
      secret = "persistent-secret"
      GraphQL::Language::Cache.new(cache_path, secret: secret).fetch(source.to_s) { :parsed }
      cache = GraphQL::Language::Cache.new(cache_path, secret: secret)

      assert_equal :parsed, cache.fetch(source.to_s) { flunk("cache was not reused") }
    end
  end

  it "doesn't reuse a cache entry with a different secret" do
    with_cache do |source, cache_path, _cache|
      GraphQL::Language::Cache.new(cache_path, secret: "first-secret").fetch(source.to_s) { :parsed }
      cache = GraphQL::Language::Cache.new(cache_path, secret: "second-secret")

      assert_equal :reparsed, cache.fetch(source.to_s) { :reparsed }
    end
  end

  it "uses the file contents instead of mtime for cache keys" do
    with_cache do |source, _cache_path, cache|
      original_mtime = File.mtime(source)
      calls = 0
      cache.fetch(source.to_s) { calls += 1; :original }

      File.utime(original_mtime + 1, original_mtime + 1, source)
      assert_equal :original, cache.fetch(source.to_s) { flunk("mtime changed the cache key") }

      source.write("type Query { goodbye: String }\n")
      File.utime(original_mtime, original_mtime, source)
      assert_equal :updated, cache.fetch(source.to_s) { calls += 1; :updated }
      assert_equal 2, calls
    end
  end

  it "doesn't load an unsigned cache entry" do
    with_cache do |source, cache_path, cache|
      cache.fetch(source.to_s) { :trusted }
      cache_file = cache_path.children.first
      cache_file.binwrite(Marshal.dump(GraphQLLanguageCacheGadget.new))
      GraphQLLanguageCacheGadget.called = false

      assert_equal :reparsed, cache.fetch(source.to_s) { :reparsed }
      refute GraphQLLanguageCacheGadget.called
    end
  end

  it "cleans up temporary files when writing fails" do
    with_cache do |source, cache_path, cache|
      assert_raises(IOError) do
        File.stub(:rename, ->(*) { raise IOError, "rename failed" }) do
          cache.fetch(source.to_s) { :parsed }
        end
      end

      assert_empty cache_path.children
    end
  end

  it "returns the payload when the cache path cannot be replaced" do
    with_cache do |source, cache_path, cache|
      cache.fetch(source.to_s) { :initial }
      cache_file = cache_path.children.first
      cache_file.unlink
      cache_file.mkpath

      assert_equal :parsed, cache.fetch(source.to_s) { :parsed }
      assert_empty cache_file.children
    end
  end
end
