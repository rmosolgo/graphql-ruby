# frozen_string_literal: true

require "optparse"
require "pathname"
require "yard"

module GraphQLDocs
  class YardMigrator
    AUTO_TAGS = %w[param return raise raises example see deprecated option yield yieldparam yieldreturn api !attribute !method].freeze
    MANUAL_TAGS = %w[
      private abstract overload !scope macro !macro note since todo version author
    ].freeze
    TAG_LINE = /\A@([A-Za-z0-9_!]+)(?:\s+(.*))?\z/.freeze
    COMMENT_LINE = /\A(?<indent>\s*)#(?:(?:[ \t](?<text>.*?))|(?<text>))(?<newline>\r?\n)?\z/.freeze
    YARD_LINK = /\{([^{}]+)\}/.freeze

    Result = Struct.new(:path, :content, :changed, :pending, :unknown, keyword_init: true)

    attr_reader :root

    def initialize(root: Dir.pwd, paths: nil)
      @root = File.expand_path(root)
      @paths = paths || Dir[File.join(@root, "lib", "**", "*.rb")].sort
      @factory = YARD::Tags::Library.default_factory
    end

    def run(mode: :check)
      results = @paths.map { |path| migrate_file(path) }
      if mode == :write
        results.each do |result|
          next unless result.changed

          File.write(result.path, result.content)
        end
      elsif mode == :dry_run
        results.each { |result| print_diff(result) if result.changed }
      end
      results
    end

    def migrate_file(path)
      source = File.read(path)
      content = source.dup
      pending = []
      unknown = []
      blocks = comment_blocks(source)
      blocks.reverse_each do |block|
        original = source.byteslice(block[:start]...block[:finish])
        replacement, block_pending, block_unknown = migrate_block(block[:lines], path)
        pending.concat(block_pending)
        unknown.concat(block_unknown)
        next if replacement == original

        content = content.byteslice(0, block[:start]) + replacement + content.byteslice(block[:finish], content.bytesize)
      end
      Result.new(path: path, content: content, changed: content != source, pending: pending, unknown: unknown)
    end

    private

    def comment_blocks(source)
      blocks = []
      offset = 0
      current = nil
      source.split(/(?<=\n)/).each do |line|
        match = COMMENT_LINE.match(line)
        if match
          current ||= { start: offset, lines: [] }
          current[:lines] << { line: line, indent: match[:indent], text: match[:text].to_s, newline: match[:newline] }
        elsif current
          current[:finish] = offset
          blocks << current
          current = nil
        end
        offset += line.bytesize
      end
      if current
        current[:finish] = source.bytesize
        blocks << current
      end
      blocks
    end

    def migrate_block(lines, path)
      base_indent = lines.first.fetch(:indent)
      source_lines = lines.map { |line| line.fetch(:text) }
      tags, body = extract_tags(source_lines, path)
      pending = tags.filter_map { |tag| tag[:pending] }
      unknown = tags.filter_map { |tag| tag[:unknown] }
      return [render_lines(lines, source_lines), pending, unknown] if tags.none? { |tag| tag[:auto] }

      sections = Hash.new { |hash, key| hash[key] = [] }
      transformed_body = body.map { |line| transform_links(line) }
      tags.each do |tag|
        next unless tag[:auto]

        case tag[:name]
        when "param"
          sections["Parameters"] << parameter_line(tag)
        when "option"
          sections["Options"] << option_line(tag)
        when "return"
          sections["Returns"] << value_line(tag)
        when "raise"
          sections["Raises"] << value_line(tag)
        when "example"
          sections["Examples"] << example_block(tag)
        when "see"
          transformed_body << see_line(tag)
        when "deprecated"
          description = tag[:raw].lines.map(&:strip).reject(&:empty?).join(" ")
          transformed_body << "**Deprecated:** #{transform_links(description)}"
        when "yield"
          description = tag[:raw].lines.map(&:strip).reject(&:empty?).join(" ")
          transformed_body << "**Yields:** #{transform_links(description)}"
        when "yieldparam"
          sections["Yields"] << parameter_line(tag)
        when "yieldreturn"
          sections["Yields"] << value_line(tag)
        when "api"
          description = tag[:raw].lines.map(&:strip).reject(&:empty?).join(" ")
          transformed_body << "**API:** #{transform_links(description)}"
        when "!attribute"
          sections["Attributes"] << attribute_line(tag)
        when "!method"
          transformed_body << method_line(tag)
        end
      end

      tags.each do |tag|
        next unless tag[:pending] || tag[:unknown]

        transformed_body << "" unless transformed_body.empty? || transformed_body.last.empty?
        transformed_body.concat(tag.fetch(:source_lines))
      end

      rendered = transformed_body.dup
      sections.each do |title, entries|
        rendered << "" unless rendered.empty? || rendered.last.empty?
        rendered << "**#{title}**"
        rendered << ""
        entries.each_with_index do |entry, index|
          rendered << "" if index.positive? && entry.is_a?(Array)
          rendered.concat(entry.is_a?(Array) ? entry : [entry])
        end
      end
      rendered = rendered.reverse.drop_while(&:empty?).reverse
      [render_lines(lines, rendered, base_indent: base_indent), pending, unknown]
    end

    def extract_tags(lines, path)
      body = []
      tags = []
      index = 0
      while index < lines.length
        match = TAG_LINE.match(lines[index])
        unless match
          body << lines[index]
          index += 1
          next
        end

        name = match[1].downcase
        raw_lines = [match[2].to_s]
        index += 1
        while index < lines.length && !TAG_LINE.match?(lines[index])
          raw_lines << lines[index]
          index += 1
        end
        tag = parse_tag(name, raw_lines, path)
        tags << tag
      end
      [tags, body]
    end

    def parse_tag(name, raw_lines, path)
      raw = raw_lines.join("\n").strip
      name = "raise" if name == "raises"
      tag = { name: name, raw: raw, lines: raw_lines, auto: AUTO_TAGS.include?(name) }
      tag[:source_lines] = ["@#{name} #{raw_lines.first}".rstrip, *raw_lines.drop(1)]
      unless AUTO_TAGS.include?(name) || MANUAL_TAGS.include?(name)
        tag[:unknown] = "#{path}: unknown YARD tag @#{name}"
        return tag
      end
      if MANUAL_TAGS.include?(name)
        tag[:pending] = "#{path}: manual YARD tag @#{name}"
        return tag
      end

      begin
        tag[:parsed] = case name
        when "param", "example"
          @factory.parse_tag_with_types_and_name(name, raw)
        when "return", "raise", "see"
          @factory.parse_tag_with_types(name, raw)
        when "deprecated"
          nil
        end
      rescue StandardError => error
        tag[:unknown] = "#{path}: cannot parse @#{name}: #{error.message}"
        tag[:auto] = false
      end
      tag
    end

    def parameter_line(tag)
      parsed = tag.fetch(:parsed)
      unless parsed
        match = tag.fetch(:raw).match(/\A(?:(\S+)\s+)?\[([^\]]+)\]\s*(.*)\z/m)
        return "- `#{match[1] || "value"}` (`#{match[2]}`)#{match[3].to_s.empty? ? "" : " — #{transform_links(match[3].lines.map(&:strip).join(" "))}"}" if match

        return "- `value` — #{transform_links(tag.fetch(:raw))}"
      end
      name = parsed.name || "value"
      type = format_types(parsed.types)
      description = parsed.text.to_s.lines.map(&:strip).reject(&:empty?).join(" ")
      description = transform_links(description)
      "- `#{name}`#{type.empty? ? "" : " (`#{type}`)"}#{description.empty? ? "" : " — #{description}"}"
    end

    def option_line(tag)
      parsed = tag.fetch(:parsed)
      unless parsed
        match = tag.fetch(:raw).match(/\A(\S+)\s+\[([^\]]+)\]\s+(:\S+)(?:\s+(.*))?\z/m)
        return "- `#{match[1]}.#{match[3]}` (`#{match[2]}`)#{match[4].to_s.empty? ? "" : " — #{transform_links(match[4])}"}" if match

        return "- `#{tag.fetch(:raw).lines.first.to_s.strip}`"
      end
      option_name, description = parsed.text.to_s.strip.split(/\s+/, 2)
      option_name ||= parsed.name
      name = option_name&.start_with?(":") ? "#{parsed.name}[#{option_name}]" : [parsed.name, option_name].compact.join(".")
      type = format_types(parsed.types)
      description = transform_links(description.to_s)
      "- `#{name}`#{type.empty? ? "" : " (`#{type}`)"}#{description.empty? ? "" : " — #{description}"}"
    end

    def attribute_line(tag)
      raw_lines = tag.fetch(:raw).lines.map(&:strip)
      name = raw_lines.shift.to_s
      return "- `#{name}`" if raw_lines.empty?

      return_tag = raw_lines.join(" ").sub(/\A@return\s+/, "")
      parsed = @factory.parse_tag_with_types("return", return_tag)
      description = parsed.text.to_s.lines.map(&:strip).reject(&:empty?).join(" ")
      type = format_types(parsed.types)
      "- `#{name}`#{type.empty? ? "" : " (`#{type}`)"}#{description.empty? ? "" : " — #{transform_links(description)}"}"
    end

    def method_line(tag)
      raw_lines = tag.fetch(:raw).lines.map(&:strip)
      signature = raw_lines.shift.to_s
      description = transform_links(raw_lines.join(" "))
      "**Method:** `#{signature}`#{description.empty? ? "" : " — #{description}"}"
    end

    def value_line(tag)
      parsed = tag.fetch(:parsed)
      unless parsed
        match = tag.fetch(:raw).match(/\A\[([^\]]+)\]\s*(.*)\z/m)
        return "- `#{match[1]}`#{match[2].to_s.empty? ? "" : " — #{transform_links(match[2].lines.map(&:strip).join(" "))}"}" if match

        return "- `Object` — #{transform_links(tag.fetch(:raw))}"
      end
      type = format_types(parsed.types)
      description = transform_links(parsed.text.to_s.lines.map(&:strip).reject(&:empty?).join(" "))
      "- `#{type.empty? ? "Object" : type}`#{description.empty? ? "" : " — #{description}"}"
    end

    def example_block(tag)
      raw_lines = tag.fetch(:raw).lines.map(&:rstrip)
      title = raw_lines.shift.to_s.strip
      code = raw_lines
      code = code.drop_while(&:empty?).reverse.drop_while(&:empty?).reverse
      indentation = code.reject(&:empty?).filter_map { |line| line[/\A\s+/]&.length }.min || 0
      code = code.map { |line| line.sub(/\A\s{#{indentation}}/, "") }
      ["**Example: #{title.empty? ? "Usage" : title}**", "", "```ruby", *code, "```"]
    end

    def see_line(tag)
      raw = tag.fetch(:raw)
      reference, label, suffix = if (match = raw.match(/\A\{([^\s}]+)(?:\s+([^}]+))?\}(.*)\z/m))
        [match[1], (match[2] || match[1]).delete_prefix("#"), match[3].to_s]
      else
        parts = raw.split(/\s+/, 2)
        [parts.first, parts.first.delete_prefix("#"), parts.last.to_s.empty? ? "" : " #{parts.last}"]
      end
      "See [#{label}](rdoc-ref:#{reference})#{transform_links(suffix)}"
    end

    def format_types(types)
      Array(types).join(", ").strip
    end

    def transform_links(text)
      text.to_s.gsub(YARD_LINK) do
        target = Regexp.last_match(1).strip
        parts = target.split(/\s+/, 2)
        reference = parts.first
        if reference.start_with?("@")
          next "`#{target}`"
        end
        label = parts.last || reference
        label = reference.delete_prefix("#").tr("_", " ") if parts.length == 1 && reference.start_with?("#")
        "[#{label}](rdoc-ref:#{reference})"
      end
    end

    def render_lines(original_lines, content_lines, base_indent: original_lines.first.fetch(:indent))
      newline = original_lines.last.fetch(:newline) || (original_lines.first.fetch(:newline) || "\n")
      content_lines.map.with_index do |line, index|
        suffix = index == content_lines.length - 1 ? newline : "\n"
        line.empty? ? "#{base_indent}##{suffix}" : "#{base_indent}# #{line}#{suffix}"
      end.join
    end

    def print_diff(result)
      old = File.read(result.path).lines
      new = result.content.lines
      puts "--- #{result.path}"
      puts "+++ #{result.path} (RDoc)"
      puts old.each_with_index.map { |line, index| line == new[index] ? nil : "-#{line}" }.compact
      puts new.each_with_index.map { |line, index| line == old[index] ? nil : "+#{line}" }.compact
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { mode: :check }
  OptionParser.new do |parser|
    parser.banner = "Usage: ruby tool/docs/migrate_yard.rb [options] [files...]"
    parser.on("--check", "Report comments that would be converted") { options[:mode] = :check }
    parser.on("--write", "Write converted comments") { options[:mode] = :write }
    parser.on("--dry-run", "Print converted comments") { options[:mode] = :dry_run }
    parser.on("--root PATH", "Repository root") { |path| options[:root] = path }
  end.parse!
  paths = ARGV.empty? ? nil : ARGV.map { |path| File.expand_path(path, options.fetch(:root, Dir.pwd)) }
  results = GraphQLDocs::YardMigrator.new(root: options.fetch(:root, Dir.pwd), paths: paths).run(mode: options.fetch(:mode))
  results.each do |result|
    result.pending.each { |message| warn "pending: #{message}" }
    result.unknown.each { |message| warn "error: #{message}" }
    puts "convert: #{result.path}" if result.changed && options.fetch(:mode) == :check
  end
  exit 1 if results.any? { |result| result.pending.any? || result.unknown.any? || (result.changed && options.fetch(:mode) == :check) }
end
