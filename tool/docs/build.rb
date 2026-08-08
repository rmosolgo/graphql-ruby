# frozen_string_literal: true

require "fileutils"
require "rubygems/package"
require "open3"
require "rdoc"
require "tmpdir"
require_relative "generator"

module GraphQLDocs
  class Build
    VERSION_PATTERN = /\A\d+\.\d+\.\d+(?:[.-][0-9A-Za-z.]+)?\z/.freeze

    attr_reader :root

    def initialize(root: Dir.pwd)
      @root = File.expand_path(root)
    end

    def build_site(output: "tmp/rdoc-site")
      build(source_root: root, source_files: site_sources(root), output: output)
    end

    def build_version(version, output: "tmp/rdoc-api/#{version}")
      validate_version!(version)

      Dir.mktmpdir("graphql-ruby-docs") do |directory|
        gem_path = fetch_gem(version, directory)
        extracted = File.join(directory, "graphql-#{version}")
        Gem::Package.new(gem_path).extract_files(extracted)
        build(
          source_root: extracted,
          source_files: gem_sources(extracted),
          output: output,
          title: "GraphQL Ruby #{version} API Documentation",
        )
      end
    end

    private

    def build(source_root:, source_files:, output:, title: "GraphQL Ruby API Documentation")
      output_path = absolute_path(output)
      FileUtils.rm_rf(output_path)

      Dir.chdir(source_root) do
        options = RDoc::Options.new
        options.files = source_files
        options.main_page = "readme.md"
        options.markup = "markdown"
        options.op_dir = output_path
        options.title = title
        options.visibility = :public
        options.generator = RDoc::Generator::GraphQLRuby
        RDoc::RDoc.new.document(options)
      end
      output_path
    end

    def site_sources(source_root)
      docs_root = File.join(source_root, "docs")
      guides_root = Dir[File.join(docs_root, "**", "*.md")].empty? ? "guides" : "docs"
      [
        "readme.md",
        *Dir[File.join("lib", "**", "*.rb")],
        *Dir[File.join(guides_root, "**", "*.md")].reject { |path| generated_guide?(path) },
      ]
    end

    def gem_sources(source_root)
      [
        "readme.md",
        *Dir[File.join(source_root, "lib", "**", "*.rb")].map { |path| path.delete_prefix("#{source_root}/") },
      ]
    end

    def generated_guide?(path)
      path.match?(%r{\A(?:guides|docs)/(?:_site|yardoc|_includes|_layouts|_plugins)/})
    end

    def absolute_path(path)
      File.expand_path(path, root)
    end

    def validate_version!(version)
      return if VERSION_PATTERN.match?(version)

      raise ArgumentError, "Invalid GraphQL-Ruby version: #{version.inspect}"
    end

    def fetch_gem(version, directory)
      output, error, status = Open3.capture3("gem", "fetch", "graphql", "--version=#{version}", chdir: directory)
      raise "Unable to fetch graphql-#{version}: #{error}\n#{output}" unless status.success?

      gem_path = File.join(directory, "graphql-#{version}.gem")
      raise "gem fetch did not create #{gem_path}" unless File.file?(gem_path)

      gem_path
    end
  end
end
