# frozen_string_literal: true

require "json"
require "optparse"

module GraphQLDocs
  class VersionCheck
    def initialize(root:, version:)
      @root = File.expand_path(root)
      @version = version
    end

    def check
      errors = []
      errors << "missing index.html" unless File.file?(File.join(@root, "index.html"))
      index_path = File.join(@root, "js", "search_data.js")
      errors << "missing js/search_data.js" unless File.file?(index_path)
      if File.file?(index_path)
        data = File.read(index_path).strip.delete_prefix("var search_data = ").delete_suffix(";")
        begin
          index = JSON.parse(data).fetch("index")
          errors << "search index is empty" if index.empty?
        rescue JSON::ParserError, KeyError => error
          errors << "invalid search index: #{error.message}"
        end
      end
      errors << "versioned output contains unresolved RDoc references" if Dir[File.join(@root, "**", "*.html")].any? do |path|
        File.read(path, encoding: "UTF-8").include?("rdoc-ref:")
      end
      errors
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/version_check.rb --root PATH --version VERSION"
    parser.on("--root PATH", "Versioned documentation root") { |path| options[:root] = path }
    parser.on("--version VERSION", "Expected GraphQL-Ruby version") { |version| options[:version] = version }
  end.parse!
  abort "--root and --version are required" unless options[:root] && options[:version]
  errors = GraphQLDocs::VersionCheck.new(root: options.fetch(:root), version: options.fetch(:version)).check
  errors.each { |error| warn "#{options.fetch(:version)}: #{error}" }
  puts "Validated versioned API docs for #{options.fetch(:version)}" if errors.empty?
  exit 1 unless errors.empty?
end
