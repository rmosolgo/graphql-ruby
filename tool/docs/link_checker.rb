# frozen_string_literal: true

require "cgi"
require "json"
require "find"
require "optparse"
require "set"
require "uri"

module GraphQLDocs
  class LinkChecker
    LINK_PATTERN = /(?:href|src)\s*=\s*["']([^"']+)["']/i.freeze
    FRAGMENT_PATTERN = /(?:id|name)\s*=\s*["']([^"']+)["']/i.freeze
    EXTERNAL_SCHEMES = %w[data file http https javascript mailto].freeze

    def initialize(root, allow_root_links: false, root_links: nil)
      @root = File.expand_path(root)
      @allow_root_links = allow_root_links
      @root_links = root_links && File.expand_path(root_links)
      @files = Find.find(@root).select { |path| File.file?(path) }.to_set
    end

    def check
      missing = []
      html_files.each do |source|
        File.read(source, encoding: "UTF-8").scan(LINK_PATTERN).flatten.each do |raw_target|
          target, fragment = split_target(raw_target)
          next if external?(target)
          if target.start_with?("/") && @allow_root_links
            if @root_links
              destination = resolve_root_link(target)
              unless destination && File.file?(destination)
                missing << [source, raw_target, "file"]
                next
              end
              if fragment && !fragment_present?(destination, fragment)
                missing << [source, raw_target, "fragment"]
              end
            end
            next
          end
          next unless document_link?(target, fragment)

          destination = resolve(source, target)
          unless File.file?(destination)
            missing << [source, raw_target, "file"]
            next
          end
          next unless fragment
          next if fragment_present?(destination, fragment)

          missing << [source, raw_target, "fragment"]
        end
      end
      report(missing)
      missing
    end

    private

    def html_files
      @files.select { |path| path.end_with?(".html") }
    end

    def split_target(raw_target)
      target, fragment = raw_target.split("#", 2)
      target ||= ""
      [target.to_s.split("?", 2).first.to_s, fragment && CGI.unescape(fragment)]
    end

    def external?(target)
      target.start_with?("#") || EXTERNAL_SCHEMES.include?(URI.parse(target).scheme)
    rescue URI::InvalidURIError
      false
    end

    def document_link?(target, fragment)
      fragment || target.start_with?("/") || target.end_with?(".html")
    end

    def resolve(source, target)
      return source if target.empty?

      path = if target.start_with?("/")
        File.join(@root, target.delete_prefix("/"))
      else
        File.expand_path(target, File.dirname(source))
      end
      path = File.join(path, "index.html") if File.directory?(path)
      path
    end

    def resolve_root_link(target)
      path = File.join(@root_links, target.delete_prefix("/"))
      candidates = [path, "#{path}.html", File.join(path, "index.html")]
      candidates.find { |candidate| File.file?(candidate) }
    end

    def fragments(path)
      File.read(path, encoding: "UTF-8").scan(FRAGMENT_PATTERN).flatten.to_set
    end

    def fragment_present?(path, fragment, visited = Set.new)
      available = fragments(path)
      return true if available.include?(fragment)

      normalized = fragment.gsub(/-+/, "-")
      return true if available.any? { |candidate| candidate.gsub(/-+/, "-") == normalized }

      return false if visited.include?(path)

      visited << path
      redirect = File.read(path, encoding: "UTF-8")[/<meta[^>]+\burl=["']?([^"'\s>]+)/i, 1]
      redirect && fragment_present?(resolve(path, redirect), fragment, visited)
    end

    def report(missing)
      missing.each { |source, target, kind| warn "#{kind}: #{source.delete_prefix("#{@root}/")} -> #{target}" }
      puts "Checked #{html_files.size} HTML files; #{missing.size} broken links"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/link_checker.rb --root PATH"
    parser.on("--root PATH", "Generated documentation root") { |path| options[:root] = path }
    parser.on("--json PATH", "Write broken links as JSON") { |path| options[:json] = path }
    parser.on("--allow-root-links", "Skip links to the published site's root") { options[:allow_root_links] = true }
    parser.on("--root-links PATH", "Published site root used to validate absolute links") { |path| options[:root_links] = path }
    parser.on("--strict", "Fail when broken links are found") { options[:strict] = true }
  end.parse!

  abort "--root is required" unless options[:root]
  missing = GraphQLDocs::LinkChecker.new(options[:root], allow_root_links: options[:allow_root_links], root_links: options[:root_links]).check
  File.write(options[:json], JSON.pretty_generate(missing.map { |source, target, kind| { "source" => source, "target" => target, "kind" => kind } }) + "\n") if options[:json]
  exit 1 if options[:strict] && !missing.empty?
end
