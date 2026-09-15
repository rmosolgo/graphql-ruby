# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "optparse"

module GraphQLDocs
  class PublishCheck
    def initialize(pages:)
      @pages = File.expand_path(pages)
      @api_docs = File.join(@pages, "api-doc")
    end

    def snapshot
      files = api_doc_files.to_h do |path|
        [relative(path), Digest::SHA256.file(path).hexdigest]
      end
      { "files" => files }
    end

    def verify(snapshot:, allowed_version: nil, expected_version: nil)
      before = snapshot.fetch("files")
      after = snapshot().fetch("files")
      changed = (before.keys | after.keys).select { |path| before[path] != after[path] }
      allowed_prefix = allowed_version && "api-doc/#{allowed_version}/"
      unexpected = changed.reject { |path| allowed_prefix && path.start_with?(allowed_prefix) }
      errors = []
      errors << "existing api-doc files changed outside #{allowed_prefix}" unless unexpected.empty?
      if expected_version
        prefix = "api-doc/#{expected_version}/"
        errors << "versioned API docs are missing" unless after.keys.any? { |path| path.start_with?(prefix) }
      end
      [errors, changed]
    end

    private

    def api_doc_files
      return [] unless Dir.exist?(@api_docs)

      Dir[File.join(@api_docs, "**", "*")].select { |path| File.file?(path) }
    end

    def relative(path)
      path.delete_prefix("#{@pages}/")
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { mode: nil }
  parser = OptionParser.new do |p|
    p.banner = "Usage: ruby tool/docs/publish_check.rb snapshot|verify [options]"
    p.on("--pages PATH", "Checked-out GitHub Pages root") { |path| options[:pages] = path }
    p.on("--snapshot PATH", "Snapshot JSON path") { |path| options[:snapshot] = path }
    p.on("--allow-version VERSION", "Allow changes under api-doc/VERSION") { |version| options[:allow_version] = version }
    p.on("--expected-version VERSION", "Require api-doc/VERSION after publishing") { |version| options[:expected_version] = version }
  end
  options[:mode] = ARGV.shift
  parser.parse!
  abort "mode must be snapshot or verify" unless ["snapshot", "verify"].include?(options[:mode])
  abort "--pages is required" unless options[:pages]
  checker = GraphQLDocs::PublishCheck.new(pages: options.fetch(:pages))
  if options[:mode] == "snapshot"
    abort "--snapshot is required" unless options[:snapshot]
    File.write(options.fetch(:snapshot), JSON.pretty_generate(checker.snapshot) + "\n")
    puts "Snapshotted #{checker.snapshot.fetch("files").size} API documentation files"
  else
    abort "--snapshot is required" unless options[:snapshot]
    snapshot = JSON.parse(File.read(options.fetch(:snapshot)))
    errors, changed = checker.verify(
      snapshot: snapshot,
      allowed_version: options[:allow_version],
      expected_version: options[:expected_version],
    )
    errors.each { |error| warn error }
    puts "Verified publication; #{changed.size} API documentation files changed"
    exit 1 unless errors.empty?
  end
end
