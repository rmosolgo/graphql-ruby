# frozen_string_literal: true

require "optparse"
require "json"

module GraphQLDocs
  # RDoc treats `rdoc-ref:` as a link target while it is rendering Markdown.
  # It must not leak into the published HTML: a leaked reference is visible to
  # readers and cannot be followed by browsers or the site link checker.
  class RDocReferenceChecker
    REFERENCE = /rdoc-ref:[A-Za-z][A-Za-z0-9_:#.?!-]*/.freeze

    def initialize(root)
      @root = File.expand_path(root)
    end

    def check
      unresolved = []
      published_files.each do |path|
        File.read(path, encoding: "UTF-8").scan(REFERENCE).uniq.each do |reference|
          unresolved << {
            "file" => path.delete_prefix("#{@root}/"),
            "reference" => reference,
          }
        end
      end
      unresolved
    end

    def report(unresolved)
      unresolved.each do |entry|
        warn "unresolved RDoc reference: #{entry.fetch("file")} -> #{entry.fetch("reference")}"
      end
      puts "Checked #{published_files.size} published files; #{unresolved.size} unresolved RDoc references"
    end

    private

    def published_files
      Dir[File.join(@root, "**", "*.html"), File.join(@root, "js", "search_data.js")].select do |path|
        File.file?(path)
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/rdoc_ref_checker.rb --root PATH"
    parser.on("--root PATH", "Generated documentation root") { |path| options[:root] = path }
    parser.on("--json PATH", "Write unresolved references as JSON") { |path| options[:json] = path }
  end.parse!

  abort "--root is required" unless options[:root]
  checker = GraphQLDocs::RDocReferenceChecker.new(options.fetch(:root))
  unresolved = checker.check
  checker.report(unresolved)
  File.write(options.fetch(:json), JSON.pretty_generate(unresolved) + "\n") if options[:json]
  exit 1 unless unresolved.empty?
end
