# frozen_string_literal: true

require "json"
require "optparse"
require "set"
require "yaml"

module GraphQLDocs
  # Check that Aliki's API search index points at real, unique documentation.
  #
  # This intentionally validates the RDoc output itself. Comparing against a
  # YARD registry would keep the retired documentation toolchain as a runtime
  # dependency after the migration.
  class Compatibility
    API_TYPES = %w[class module constant instance_method class_method].freeze

    def initialize(root: Dir.pwd)
      @root = File.expand_path(root)
    end

    def check(rdoc_index:, baseline: nil)
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
      result = { "indexed_api_entries" => entries.count { |entry| API_TYPES.include?(entry.fetch("type")) },
        "duplicate_entries" => duplicates,
        "invalid_entries" => invalid,
        "unexpected_missing" => invalid,
        "unexpected_extra" => duplicates }
      result.merge!(compare_baseline(entries, baseline)) if baseline
      result
    end

    def report(result)
      puts "Indexed API entries: #{result.fetch("indexed_api_entries")}"
      puts "Duplicate entries: #{result.fetch("duplicate_entries").size}"
      puts "Invalid entries: #{result.fetch("invalid_entries").size}"
      result.fetch("invalid_entries").each { |entry| warn "invalid: #{entry.inspect}" }
      result.fetch("duplicate_entries").each { |entry| warn "duplicate: #{entry.inspect}" }
      if result.key?("baseline_entries")
        puts "YARD baseline entries: #{result.fetch("baseline_entries")}"
        puts "Baseline missing: #{result.fetch("baseline_missing").size}"
        puts "Baseline extra: #{result.fetch("baseline_extra").size}"
        puts "Unexpected baseline missing: #{result.fetch("unexpected_baseline_missing").size}"
        puts "Unexpected baseline extra: #{result.fetch("unexpected_baseline_extra").size}"
        result.fetch("unexpected_baseline_missing").each { |entry| warn "baseline missing: #{entry.inspect}" }
        result.fetch("unexpected_baseline_extra").each { |entry| warn "baseline extra: #{entry.inspect}" }
      end
    end

    private

    def rdoc_entries(path)
      json = File.read(path).strip.delete_prefix("var search_data = ").delete_suffix(";")
      JSON.parse(json).fetch("index")
    end

    def compare_baseline(entries, path)
      data = YAML.safe_load(File.read(path), permitted_classes: [], aliases: false) || {}
      yard = entries_from_baseline(data.fetch("yard_api"))
      rdoc = entries.filter_map do |entry|
        next unless API_TYPES.include?(entry.fetch("type"))
        next if entry.fetch("snippet", "").to_s.empty?

        [entry.fetch("type"), normalize_rdoc_name(entry.fetch("type"), entry.fetch("full_name"))]
      end.to_set
      missing = yard - rdoc
      extra = rdoc - yard
      allowed_missing = entries_from_baseline(data.fetch("allowed_missing", []))
      allowed_extra = entries_from_baseline(data.fetch("allowed_extra", []))
      review = data.fetch("allowlist_review")
      raise ArgumentError, "API baseline allowlist review requires a date" unless review.fetch("reviewed_at").to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      raise ArgumentError, "API baseline allowlist review requires reasons" if [review.fetch("missing_reason"), review.fetch("extra_reason")].any? { |reason| reason.to_s.strip.empty? }
      {
        "baseline_source" => data.fetch("source"),
        "baseline_entries" => yard.size,
        "baseline_missing" => missing.sort,
        "baseline_extra" => extra.sort,
        "unexpected_baseline_missing" => (missing - allowed_missing).sort,
        "unexpected_baseline_extra" => (extra - allowed_extra).sort,
      }
    end

    def entries_from_baseline(entries)
      entries.map do |entry|
        unless entry.is_a?(Array) && entry.size == 2 && entry.all? { |value| value.is_a?(String) }
          raise ArgumentError, "API baseline entries must be [type, name] pairs"
        end

        entry
      end.to_set
    end

    def normalize_rdoc_name(type, name)
      return name unless type == "class_method"

      name.sub(/::([^:]+)\z/, ".\\1")
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
    parser.on("--json PATH", "Write the comparison report as JSON") { |path| options[:json] = path }
    parser.on("--baseline PATH", "YARD API baseline YAML") { |path| options[:baseline] = path }
    parser.on("--strict", "Fail when an indexed API entry or baseline comparison is invalid") { options[:strict] = true }
  end.parse!

  abort "--rdoc is required" unless options[:rdoc]
  checker = GraphQLDocs::Compatibility.new(root: options.fetch(:root))
  result = checker.check(rdoc_index: options.fetch(:rdoc), baseline: options[:baseline])
  checker.report(result)
  File.write(options.fetch(:json), JSON.pretty_generate(result) + "\n") if options[:json]
  strict_keys = %w[duplicate_entries invalid_entries unexpected_baseline_missing unexpected_baseline_extra]
  exit 1 if options[:strict] && strict_keys.any? { |key| result.fetch(key, []).any? }
end
