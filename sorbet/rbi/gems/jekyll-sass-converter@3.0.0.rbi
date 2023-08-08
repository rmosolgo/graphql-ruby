# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `jekyll-sass-converter` gem.
# Please instead update this file by running `bin/tapioca gem jekyll-sass-converter`.

# source://jekyll-sass-converter//lib/jekyll/source_map_page.rb#3
module Jekyll
  class << self
    # source://jekyll/4.3.2/lib/jekyll.rb#114
    def configuration(override = T.unsafe(nil)); end

    # source://jekyll/4.3.2/lib/jekyll.rb#101
    def env; end

    # source://jekyll/4.3.2/lib/jekyll.rb#145
    def logger; end

    # source://jekyll/4.3.2/lib/jekyll.rb#156
    def logger=(writer); end

    # source://jekyll/4.3.2/lib/jekyll.rb#174
    def sanitized_path(base_directory, questionable_path); end

    # source://jekyll/4.3.2/lib/jekyll.rb#133
    def set_timezone(timezone); end

    # source://jekyll/4.3.2/lib/jekyll.rb#163
    def sites; end
  end
end

# source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#14
module Jekyll::Converters; end

# source://jekyll-sass-converter//lib/jekyll/converters/sass.rb#7
class Jekyll::Converters::Sass < ::Jekyll::Converters::Scss
  # source://jekyll-sass-converter//lib/jekyll/converters/sass.rb#13
  def syntax; end
end

# source://jekyll-sass-converter//lib/jekyll/converters/sass.rb#8
Jekyll::Converters::Sass::EXTENSION_PATTERN = T.let(T.unsafe(nil), Regexp)

# source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#15
class Jekyll::Converters::Scss < ::Jekyll::Converter
  # Associate this Converter with the "page" object that manages input and output files for
  # this converter.
  #
  # Note: changing the associated sass_page during the live time of this Converter instance
  # may result in inconsistent results.
  #
  # @param page [Jekyll:Page] The sass_page for which this object acts as converter.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#52
  def associate_page(page); end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#159
  def convert(content); end

  # Dissociate this Converter with the "page" object.
  #
  # @param page [Jekyll:Page] The sass_page for which this object has acted as a converter.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#65
  def dissociate_page(page); end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#88
  def jekyll_sass_configuration; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#76
  def matches(ext); end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#80
  def output_ext(_ext); end

  # @return [Boolean]
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#84
  def safe?; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#145
  def sass_configs; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#102
  def sass_dir; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#117
  def sass_dir_relative_to_site_source; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#123
  def sass_load_paths; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#108
  def sass_style; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#98
  def syntax; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#113
  def user_sass_load_paths; end

  private

  # @return [Boolean]
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#183
  def associate_page_failed?; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#266
  def file_url_from_path(path); end

  # Adds the source-map to the source-map-page and adds it to `site.pages`.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#244
  def generate_source_map_page(source_map); end

  # Converts file urls in source map to relative paths.
  #
  # Returns processed source map string.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#231
  def process_source_map(source_map); end

  # Returns the value of the `quiet_deps`-option chosen by the user or 'false' by default.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#271
  def quiet_deps_option; end

  # The URL of the input scss (or sass) file. This information will be used for error reporting.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#188
  def sass_file_url; end

  # The Page instance for which this object acts as a converter.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#181
  def sass_page; end

  # Returns the directory that source map sources are relative to.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#220
  def sass_source_root; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#258
  def site; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#262
  def site_source; end

  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#213
  def source_map_page; end

  # Returns a source mapping url for given source-map.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#252
  def source_mapping_url; end

  # The value of the `sourcemap` option chosen by the user.
  #
  # This option controls when sourcemaps shall be generated or not.
  #
  # Returns the value of the `sourcemap`-option chosen by the user or ':always' by default.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#199
  def sourcemap_option; end

  # Determines whether a sourcemap shall be generated or not.
  #
  # Returns `true` if a sourcemap shall be generated, `false` otherwise.
  #
  # @return [Boolean]
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#206
  def sourcemap_required?; end

  # Returns the value of the `verbose`-option chosen by the user or 'false' by default.
  #
  # source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#276
  def verbose_option; end

  class << self
    # source://jekyll/4.3.2/lib/jekyll/plugin.rb#24
    def inherited(const_); end
  end
end

# source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#43
Jekyll::Converters::Scss::ALLOWED_STYLES = T.let(T.unsafe(nil), Array)

# source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#16
Jekyll::Converters::Scss::EXTENSION_PATTERN = T.let(T.unsafe(nil), Regexp)

# source://jekyll-sass-converter//lib/jekyll/converters/scss.rb#18
class Jekyll::Converters::Scss::SyntaxError < ::ArgumentError; end

# A Jekyll::Page subclass to manage the source map file associated with
# a given scss / sass page.
#
# source://jekyll-sass-converter//lib/jekyll/source_map_page.rb#6
class Jekyll::SourceMapPage < ::Jekyll::Page
  # Initialize a new SourceMapPage.
  #
  # @param css_page [Jekyll::Page] The Page object that manages the css file.
  # @return [SourceMapPage] a new instance of SourceMapPage
  #
  # source://jekyll-sass-converter//lib/jekyll/source_map_page.rb#10
  def initialize(css_page); end

  # @return [Boolean]
  #
  # source://jekyll-sass-converter//lib/jekyll/source_map_page.rb#28
  def asset_file?; end

  # source://jekyll-sass-converter//lib/jekyll/source_map_page.rb#24
  def ext; end

  # @return[String] the object as a debug String.
  #
  # source://jekyll-sass-converter//lib/jekyll/source_map_page.rb#37
  def inspect; end

  # @return [Boolean]
  #
  # source://jekyll-sass-converter//lib/jekyll/source_map_page.rb#32
  def render_with_liquid?; end

  # source://jekyll-sass-converter//lib/jekyll/source_map_page.rb#20
  def source_map(map); end
end

# source://jekyll-sass-converter//lib/jekyll-sass-converter/version.rb#3
module JekyllSassConverter; end

# source://jekyll-sass-converter//lib/jekyll-sass-converter/version.rb#4
JekyllSassConverter::VERSION = T.let(T.unsafe(nil), String)