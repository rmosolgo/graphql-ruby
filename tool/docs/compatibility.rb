# frozen_string_literal: true

require "json"
require "optparse"

module GraphQLDocs
  # Check that Aliki's API search index points at real, unique documentation.
  class Compatibility
    API_TYPES = ["class", "module", "constant", "instance_method", "class_method"].freeze

    def initialize(root: Dir.pwd)
      @root = File.expand_path(root)
    end

    def check(rdoc_index:)
      entries = rdoc_entries(rdoc_index)
      duplicates = entries
        .select { |entry| API_TYPES.include?(entry.fetch("type")) }
        .group_by { |entry| [entry.fetch("type"), entry.fetch("full_name")] }
        .filter_map { |key, values| values.size > 1 ? { "key" => key, "count" => values.size } : nil }
      invalid = entries.filter_map do |entry|
        next unless API_TYPES.include?(entry.fetch("type"))

        path, fragment = entry.fetch("path").split("#", 2)
        file = File.join(@root, path)
        reason = if !File.file?(file)
          "missing file"
        elsif fragment && !fragment_present?(file, fragment)
          "missing fragment"
        end
        reason && entry.merge("reason" => reason)
      end
      { "indexed_api_entries" => entries.count { |entry| API_TYPES.include?(entry.fetch("type")) },
        "duplicate_entries" => duplicates,
        "invalid_entries" => invalid }
    end

    def report(result)
      puts "Indexed API entries: #{result.fetch("indexed_api_entries")}"
      puts "Duplicate entries: #{result.fetch("duplicate_entries").size}"
      puts "Invalid entries: #{result.fetch("invalid_entries").size}"
      result.fetch("invalid_entries").each { |entry| warn "invalid: #{entry.inspect}" }
      result.fetch("duplicate_entries").each { |entry| warn "duplicate: #{entry.inspect}" }
    end

    private

    def rdoc_entries(path)
      json = File.read(path).strip.delete_prefix("var search_data = ").delete_suffix(";")
      JSON.parse(json).fetch("index")
    end

    def fragment_present?(path, fragment)
      html = File.read(path, encoding: "UTF-8")
      html.match?(%r{(?:id|name)=["']#{Regexp.escape(fragment)}["']})
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { root: Dir.pwd, strict: false }
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/compatibility.rb --rdoc PATH"
    parser.on("--root PATH", "Generated documentation root") { |path| options[:root] = path }
    parser.on("--rdoc PATH", "RDoc search_data.js") { |path| options[:rdoc] = path }
    parser.on("--json PATH", "Write the report as JSON") { |path| options[:json] = path }
    parser.on("--strict", "Fail when an indexed API entry is invalid") { options[:strict] = true }
  end.parse!

  abort "--rdoc is required" unless options[:rdoc]
  checker = GraphQLDocs::Compatibility.new(root: options.fetch(:root))
  result = checker.check(rdoc_index: options.fetch(:rdoc))
  checker.report(result)
  File.write(options.fetch(:json), JSON.pretty_generate(result) + "\n") if options[:json]
  strict_keys = ["duplicate_entries", "invalid_entries"]
  exit 1 if options[:strict] && strict_keys.any? { |key| result.fetch(key, []).any? }
end
