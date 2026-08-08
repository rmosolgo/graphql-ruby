# frozen_string_literal: true

require "cgi"
require "fileutils"
require "pathname"
require "yaml"
require_relative "legacy"

module GraphQLDocs
  class Redirects
    def self.generate(root:, output:, manifest: nil)
      new(root: root, output: output, manifest: manifest).generate
    end

    def initialize(root:, output:, manifest: nil)
      @root = Pathname.new(root).expand_path
      @output = Pathname.new(output).expand_path
      @manifest = Pathname.new(manifest || @root.join("docs/redirects.yml")).expand_path
    end

    def generate
      redirects.each do |entry|
        destination = destination_for(entry.fetch("destination"))
        write_redirect(entry.fetch("old_path"), destination)
      end
      redirects.size
    end

    def redirects
      config = YAML.safe_load(File.read(@manifest), permitted_classes: [], aliases: false) || {}
      explicit = Array(config.fetch("redirects", []))
      guides = if config["guide_source"]
        Dir[File.join(@root, config.fetch("guide_source"), "**", "*.md")].filter_map do |path|
          relative = Pathname.new(path).relative_path_from(@root).to_s
          next if relative.split("/").any? { |part| part.start_with?("_") || part == "yardoc" }

          source_prefix = "#{config.fetch("guide_source").delete_suffix("/")}/"
          old_relative = relative.delete_prefix(source_prefix)
          old_path = "/#{old_relative.delete_suffix(".md")}"
          { "old_path" => old_path, "destination" => { "kind" => "page", "value" => relative } }
        end
      else
        []
      end
      (explicit + guides).uniq { |entry| entry.fetch("old_path") }
    end

    private

    def destination_for(destination)
      case destination.fetch("kind")
      when "page"
        value = destination.fetch("value")
        value = value.sub(/\.md\z/, "_md.html")
        "/#{value.delete_prefix("/")}"
      when "rdoc_ref"
        resolve_rdoc_ref(destination.fetch("value"))
      else
        raise ArgumentError, "Unsupported redirect destination: #{destination.inspect}"
      end
    end

    def resolve_rdoc_ref(reference)
      data = File.read(@output.join("js/search_data.js")).strip.delete_prefix("var search_data = ").delete_suffix(";")
      entry = JSON.parse(data).fetch("index").find do |candidate|
        candidate["full_name"] == reference || candidate["full_name"]&.sub(/::([^:]+)\z/, '.\\1') == reference
      end
      raise ArgumentError, "No RDoc search entry for #{reference}" unless entry

      "/#{entry.fetch("path")}"
    end

    def write_redirect(old_path, destination)
      relative = old_path.delete_prefix("/")
      locations = [@output.join(relative, "index.html")]
      locations << @output.join("#{relative}.html") unless relative.end_with?(".html")
      locations.each do |path|
        FileUtils.mkdir_p(path.dirname)
        href = relative_url(path, destination)
        escaped_destination = CGI.escapeHTML(destination)
        html = <<~HTML
          <!doctype html>
          <html lang="en">
          <head>
          <meta charset="utf-8">
          <meta http-equiv="refresh" content="0; url=#{escaped_destination}">
          <link rel="canonical" href="#{escaped_destination}">
          <title>Redirecting to GraphQL Ruby documentation</title>
          </head>
          <body>
          <p>This page moved to <a href="#{href}">#{escaped_destination}</a>.</p>
          <script>window.location.replace(#{destination.to_json});</script>
          </body>
          </html>
        HTML
        File.write(path, html)
      end
    end

    def relative_url(path, destination)
      @output.join(destination.delete_prefix("/")).relative_path_from(path.dirname).to_s
    end
  end
end
