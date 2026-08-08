# frozen_string_literal: true

require "optparse"
require "uri"

module GraphQLDocs
  class GuideMigrator
    FRONT_MATTER = /\A---\s*\n(.*?)\n---\s*\n/m.freeze
    API_DOC = /\{\{\s*["']([^"']+)["']\s*\|\s*api_doc\s*\}\}/.freeze
    PLAIN_REFERENCE = /\{\{\s*["']([^"']+)["']\s*\}\}/.freeze
    SITE_BASE_URL = /\{\{\s*site\.base_url\s*\}\}/.freeze
    INTERNAL_LINK = /\{%\s*internal_link\s+["']([^"']+)["']\s*,\s*["']([^"']+)["']\s*,?\s*%\}/.freeze
    IMAGE = /\{\{\s*["']([^"']+)["']\s*\|\s*link_to_img\s*:\s*["']([^"']+)["']\s*\}\}/.freeze
    OPEN_ISSUE = /\{%\s*open_an_issue\s+["']([^"']+)["'](?:\s*,\s*["']([^"']*)["'])?\s*%\}/.freeze
    CALLOUT = /\{%\s*callout\s+(\w+)\s*%\}\s*\n(.*?)\{%\s*endcallout\s*%\}/m.freeze
    GUIDE_LINK = /\]\((?![\/#]|https?:|mailto:|rdoc-ref:)([A-Za-z][\w-]*(?:\/[A-Za-z0-9_.-]+)*(?:#[^)]+)?)\)/.freeze
    RDOC_REFERENCE = /rdoc-ref:([A-Za-z][\w:#.?!-]*)/.freeze
    GUIDE_ROOTS = %w[
      authorization changesets dataloader defer development errors execution faq fields
      getting_started javascript_client language_tools limiters mutations object_cache
      operation_store pagination pro queries related_projects relay schema subscriptions
      testing type_definitions
    ].freeze

    attr_reader :paths

    def initialize(root: Dir.pwd, paths: nil)
      @root = File.expand_path(root)
      @paths = paths || Dir[File.join(@root, "guides", "**", "*.md")].sort
    end

    def run(write: false)
      results = @paths.map { |path| [path, migrate(File.read(path))] }
      results.each { |path, content| File.write(path, content) if write && content != File.read(path) }
      results
    end

    def migrate(content)
      title = content[FRONT_MATTER, 1]&.then { |front| front[/^title:\s*["']?([^"'\n]+)["']?\s*$/i, 1] }&.strip
      content = content.sub(FRONT_MATTER, title ? "# #{title}\n\n" : "")
      content = content.gsub(API_DOC) { api_link(Regexp.last_match(1)) }
      content = content.gsub(PLAIN_REFERENCE) { api_link(Regexp.last_match(1)) }
      content = content.gsub(SITE_BASE_URL, "")
      content = content.gsub(INTERNAL_LINK) { "[#{Regexp.last_match(1)}](#{Regexp.last_match(2)})" }
      content = content.gsub(IMAGE) { "![#{Regexp.last_match(2)}](#{Regexp.last_match(1)})" }
      content = content.gsub(OPEN_ISSUE) { issue_link(Regexp.last_match(1), Regexp.last_match(2)) }
      content = content.gsub(CALLOUT) do
        heading = Regexp.last_match(1).capitalize
        body = Regexp.last_match(2).lines.map { |line| line.strip.empty? ? ">" : "> #{line.rstrip}" }.join("\n")
        "> **#{heading}:**\n>\n#{body}\n"
      end
      content = normalize_guide_links(content)
      content.sub(/\n+\z/, "\n")
    end

    private

    def api_link(reference)
      reference = normalize_api_reference(reference)
      "[#{reference}](rdoc-ref:#{reference})"
    end

    def normalize_api_reference(reference)
      return reference if reference.start_with?("GraphQL::", "#")

      root = reference.split("::", 2).first.split(/[.#]/, 2).first
      GUIDE_API_ROOTS.include?(root) ? "GraphQL::#{reference}" : reference
    end

    def normalize_guide_links(content)
      content = content.gsub(RDOC_REFERENCE) do
        "rdoc-ref:#{normalize_api_reference(Regexp.last_match(1))}"
      end
      content.gsub(GUIDE_LINK) do
        target = Regexp.last_match(1)
        root = target.split("/", 2).first.split("#", 2).first
        GUIDE_ROOTS.include?(root) ? "](/#{target})" : "](#{target})"
      end
    end

    GUIDE_API_ROOTS = %w[
      Analysis Authorization Dataloader Defer Error Execution Field Language Limiters Mutation
      ObjectCache Pagination Parser Query Relay Schema Subscriptions Testing Trace Tracing Types
    ].freeze

    def issue_link(title, body)
      params = URI.encode_www_form("title" => title, "body" => body.to_s)
      "[open an issue](https://github.com/rmosolgo/graphql-ruby/issues/new?#{params})"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { root: Dir.pwd, write: false }
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/migrate_guides.rb [options] [files...]"
    parser.on("--write", "Write converted guides") { options[:write] = true }
    parser.on("--check", "Fail when a guide needs conversion") { options[:check] = true }
    parser.on("--root PATH", "Repository root") { |path| options[:root] = path }
  end.parse!
  paths = ARGV.empty? ? nil : ARGV.map { |path| File.expand_path(path, options.fetch(:root)) }
  results = GraphQLDocs::GuideMigrator.new(root: options.fetch(:root), paths: paths).run(write: options.fetch(:write))
  changed = results.select { |path, content| content != File.read(path) }.map(&:first)
  changed.each { |path| puts "convert: #{path}" }
  exit 1 if options[:check] && changed.any?
end
