# frozen_string_literal: true

require "optparse"
require "yaml"

module GraphQLDocs
  # Verifies that API-specific guides have moved into source comments and that
  # every other guide remains an explicitly classified standalone page.
  class GuideAudit
    MANIFEST = "docs/guide_classification.yml"
    GENERATED_PREFIX = "guides/yardoc/"

    def initialize(root: Dir.pwd)
      @root = File.expand_path(root)
      @manifest = YAML.load_file(File.join(@root, MANIFEST))
    end

    def check
      errors = []
      guides = markdown_guides
      api_entries = @manifest.fetch("api_comments")
      standalone = @manifest.fetch("standalone")
      policy = @manifest.fetch("standalone_policy")
      errors << "standalone policy must explain the classification" if policy.to_s.strip.empty?

      api_paths = api_entries.map { |entry| entry.fetch("guide") }
      generated = generated_guides
      classified = api_paths + standalone + generated

      errors << "duplicate guide classification" unless classified.uniq.length == classified.length
      missing = guides - classified
      errors.concat(missing.map { |path| "#{path}: missing classification" })
      unknown = classified - guides
      errors.concat(unknown.map { |path| "#{path}: does not exist" })

      api_entries.each do |entry|
        check_api_entry(entry, errors)
      end

      errors.each { |error| warn error }
      errors
    end

    private

    def markdown_guides
      Dir[File.join(@root, "guides", "**", "*.md")].map do |path|
        path.delete_prefix("#{@root}/")
      end.sort
    end

    def generated_guides
      Array(@manifest["generated_api"]).flat_map do |pattern|
        Dir[File.join(@root, pattern)].map { |path| path.delete_prefix("#{@root}/") }
      end.sort
    end

    def check_api_entry(entry, errors)
      guide = entry.fetch("guide")
      source = entry.fetch("source")
      constant = entry.fetch("constant")
      guide_path = File.join(@root, guide)
      source_path = File.join(@root, source)

      errors << "#{guide}: source is missing" unless File.file?(source_path)
      max_lines = entry.fetch("max_lines", 50)
      errors << "#{guide}: guide exceeds its documented migration size" if File.readlines(guide_path).length > max_lines

      if entry["kind"] == "hybrid" && entry.fetch("rationale", "").to_s.strip.empty?
        errors << "#{guide}: hybrid API guide requires a rationale"
      end

      unless File.file?(guide_path) && File.read(guide_path).include?("rdoc-ref:#{constant}")
        errors << "#{guide}: entry point must link to #{constant}"
      end

      return unless File.file?(source_path)

      source_text = File.read(source_path)
      marker = "migrated from #{guide}"
      errors << "#{source}: missing migration marker for #{guide}" unless source_text.include?(marker)
      declaration = constant.split(/[.#]/, 2).first.split("::").last
      errors << "#{source}: missing #{constant} declaration" unless source_text.include?(declaration)

      Array(entry["required_sections"]).each do |section|
        errors << "#{source}: missing migrated section #{section.inspect}" unless source_text.include?(section)
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { root: Dir.pwd }
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/guide_audit.rb [options]"
    parser.on("--root PATH", "Repository root") { |path| options[:root] = path }
  end.parse!
  exit 1 unless GraphQLDocs::GuideAudit.new(root: options.fetch(:root)).check.empty?
end
