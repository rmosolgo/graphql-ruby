# frozen_string_literal: true

require "json"
require "fileutils"
require "logger"
require "optparse"
require "pathname"
require "time"
require "yard"

module GraphQLDocs
  class Inventory
    DYNAMIC_TAGS = %w[@!attribute @!method @!scope @macro @!macro @overload].freeze

    attr_reader :root

    def initialize(root: Dir.pwd)
      @root = Pathname(root).expand_path
    end

    def collect
      ruby_files = files("lib/**/*.rb")
      guide_files = files("guides/**/*.md")

      {
        "generated_at" => Time.now.utc.iso8601,
        "ruby_files" => ruby_files.map { |file| relative(file) },
        "yard_tags" => yard_tags(ruby_files),
        "yard_links" => yard_links(ruby_files),
        "dynamic_api_tags" => dynamic_api_tags(ruby_files),
        "guides" => guide_inventory(guide_files),
        "yard_objects" => yard_objects(ruby_files),
      }
    end

    def write(json_path: nil, markdown_path: nil)
      inventory = collect
      write_file(json_path, JSON.pretty_generate(inventory) + "\n") if json_path
      write_file(markdown_path, markdown(inventory)) if markdown_path
      puts JSON.pretty_generate(inventory) unless json_path || markdown_path
    end

    private

    def files(pattern)
      Dir[root.join(pattern).to_s].sort
    end

    def relative(path)
      Pathname(path).relative_path_from(root).to_s
    end

    def read(path)
      File.read(path, encoding: "UTF-8")
    end

    def write_file(path, content)
      destination = Pathname(path)
      destination = root.join(destination) unless destination.absolute?
      FileUtils.mkdir_p(destination.dirname)
      File.write(destination, content)
    end

    def yard_tags(files)
      tags = Hash.new { |hash, key| hash[key] = [] }
      files.each do |file|
        read(file).each_line.with_index(1) do |line, line_number|
          if (match = line.match(/^\s*#\s*@([A-Za-z_!][A-Za-z0-9_]*)\b/))
            tags["@#{match[1]}"] << { "file" => relative(file), "line" => line_number }
          end
        end
      end
      tags.sort.to_h
    end

    def yard_links(files)
      links = []
      files.each do |file|
        read(file).each_line.with_index(1) do |line, line_number|
          next unless line.include?("{") && line.include?("}")

          links << { "file" => relative(file), "line" => line_number, "text" => line.strip }
        end
      end
      links
    end

    def dynamic_api_tags(files)
      entries = []
      files.each do |file|
        read(file).each_line.with_index(1) do |line, line_number|
          tag = DYNAMIC_TAGS.find { |candidate| line.match?(/^\s*#\s*#{Regexp.escape(candidate)}\b/) }
          entries << { "tag" => tag, "file" => relative(file), "line" => line_number } if tag
        end
      end
      entries
    end

    def guide_inventory(files)
      files.map do |file|
        content = read(file)
        front_matter = content[/\A---\s*\n(.*?)\n---\s*\n/m, 1]
        liquid_tags = content.scan(/{%\s*([A-Za-z_][A-Za-z0-9_]*)/).flatten.uniq.sort
        {
          "path" => relative(file),
          "url" => front_matter_value(front_matter, "url") || "/#{relative(file).sub(%r{\Aguides/}, "").sub(/\.md\z/, "")}",
          "liquid_tags" => liquid_tags,
        }
      end
    end

    def front_matter_value(front_matter, key)
      return unless front_matter

      match = front_matter.match(/^#{Regexp.escape(key)}:\s*["']?([^"'\n]+)["']?\s*$/)
      match && match[1].strip
    end

    def yard_objects(files)
      YARD::Registry.clear
      YARD::Logger.instance.level = Logger::ERROR
      YARD.parse(files)
      YARD::Registry.all(:class, :module, :method, :constant).filter_map do |object|
        next if object.visibility == :private

        {
          "name" => object.path.to_s,
          "type" => object.type.to_s,
          "visibility" => object.visibility.to_s,
          "file" => object.file && relative(object.file),
          "line" => object.line,
        }
      end.sort_by { |object| [object["type"], object["name"]] }
    end

    def markdown(inventory)
      tags = inventory.fetch("yard_tags")
      guides = inventory.fetch("guides")
      objects = inventory.fetch("yard_objects")
      lines = ["# RDoc Migration Inventory", "", "Generated at: `#{inventory.fetch("generated_at")}`", ""]
      lines << "## YARD tags"
      lines << ""
      tags.each { |tag, entries| lines << "- `#{tag}`: #{entries.size}" }
      lines << ""
      lines << "## Dynamic API tags"
      lines << ""
      inventory.fetch("dynamic_api_tags").each do |entry|
        lines << "- `#{entry.fetch("tag")}` — `#{entry.fetch("file")}:#{entry.fetch("line")}`"
      end
      lines << ""
      lines << "## Guides"
      lines << ""
      guides.each do |guide|
        liquid = guide.fetch("liquid_tags").empty? ? "none" : guide.fetch("liquid_tags").join(", ")
        lines << "- `#{guide.fetch("path")}` → `#{guide.fetch("url")}` (Liquid: #{liquid})"
      end
      lines << ""
      lines << "## Public YARD objects"
      lines << ""
      lines << "- #{objects.size} objects"
      lines << ""
      lines.join("\n")
    end
  end
end

options = { root: Dir.pwd }
OptionParser.new do |parser|
  parser.banner = "Usage: ruby tool/docs/inventory.rb [options]"
  parser.on("--root PATH", "Repository root") { |path| options[:root] = path }
  parser.on("--json PATH", "Write JSON inventory") { |path| options[:json] = path }
  parser.on("--markdown PATH", "Write Markdown inventory") { |path| options[:markdown] = path }
end.parse!

GraphQLDocs::Inventory.new(root: options[:root]).write(json_path: options[:json], markdown_path: options[:markdown])
