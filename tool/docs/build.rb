# frozen_string_literal: true

require "fileutils"
require "rubygems/package"
require "open3"
require "rdoc"
require "tmpdir"
require "pathname"
require_relative "generator"
require_relative "legacy"
require_relative "redirects"

module GraphQLDocs
  class Build
    VERSION_PATTERN = /\A\d+\.\d+\.\d+(?:[.-][0-9A-Za-z.]+)?\z/.freeze

    attr_reader :root

    def initialize(root: Dir.pwd)
      @root = File.expand_path(root)
    end

    def build_site(output: "tmp/rdoc-site")
      output_path = build(source_root: root, source_files: site_sources(root), output: output)
      copy_guide_assets(output_path)
      GraphQLDocs::LegacyAnchors.install(root: output_path)
      GraphQLDocs::Redirects.generate(root: root, output: output_path)
      output_path
    end

    def build_version(version, output: "tmp/rdoc-api/#{version}")
      validate_version!(version)

      Dir.mktmpdir("graphql-ruby-docs") do |directory|
        gem_path = fetch_gem(version, directory)
        extracted = File.join(directory, "graphql-#{version}")
        Gem::Package.new(gem_path).extract_files(extracted)
        output_path = build(
          source_root: extracted,
          source_files: gem_sources(extracted),
          output: output,
          title: "GraphQL Ruby #{version} API Documentation",
        )
        GraphQLDocs::LegacyAnchors.install(root: output_path)
        output_path
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
      # RDoc writes a timestamped cache beside the generated site. It is not
      # part of the published output and would make reproducibility checks
      # fail on every build.
      FileUtils.rm_f(File.join(output_path, "created.rid"))
      output_path
    end

    def site_sources(source_root)
      docs_root = File.join(source_root, "docs")
      docs = Dir[File.join(docs_root, "**", "*.md")].reject { |path| generated_guide?(path) }
      guides = Dir[File.join(source_root, "guides", "**", "*.md")].reject { |path| generated_guide?(path) }
      [
        "readme.md",
        *Dir[File.join("lib", "**", "*.rb")],
        *docs,
        *guides,
      ]
    end

    def copy_guide_assets(output_path)
      extensions = ["png", "gif", "jpg", "jpeg", "svg", "webp"]
      Dir[File.join(root, "guides", "**", "*")].select do |path|
        File.file?(path) && extensions.include?(File.extname(path).delete_prefix(".").downcase)
      end.each do |path|
        relative = Pathname.new(path).relative_path_from(Pathname.new(root).join("guides")).to_s
        destination = Pathname.new(output_path).join(relative)
        FileUtils.mkdir_p(destination.dirname)
        FileUtils.cp(path, destination)
      end
      cname = Pathname.new(root).join("guides/CNAME")
      FileUtils.cp(cname, Pathname.new(output_path).join("CNAME")) if cname.file?
    end

    def gem_sources(source_root)
      [
        "readme.md",
        *Dir[File.join(source_root, "lib", "**", "*.rb")].map { |path| path.delete_prefix("#{source_root}/") },
      ]
    end

    def generated_guide?(path)
      relative = Pathname.new(path).expand_path.relative_path_from(Pathname.new(root)).to_s
      relative.match?(%r{\A(?:guides|docs)/(?:_site|yardoc|_includes|_layouts|_plugins)(?:/|\z)})
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
