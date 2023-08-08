# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `jekyll-redirect-from` gem.
# Please instead update this file by running `bin/tapioca gem jekyll-redirect-from`.

class Jekyll::Document
  include ::JekyllRedirectFrom::Redirectable
end

class Jekyll::Page
  include ::JekyllRedirectFrom::Redirectable
end

# source://jekyll-redirect-from//lib/jekyll-redirect-from/version.rb#3
module JekyllRedirectFrom; end

# Jekyll classes which should be redirectable
#
# source://jekyll-redirect-from//lib/jekyll-redirect-from.rb#9
JekyllRedirectFrom::CLASSES = T.let(T.unsafe(nil), Array)

# Stubbed LiquidContext to support relative_url and absolute_url helpers
#
# source://jekyll-redirect-from//lib/jekyll-redirect-from/context.rb#5
class JekyllRedirectFrom::Context
  # @return [Context] a new instance of Context
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/context.rb#8
  def initialize(site); end

  # source://jekyll-redirect-from//lib/jekyll-redirect-from/context.rb#12
  def registers; end

  # Returns the value of attribute site.
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/context.rb#6
  def site; end
end

# source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#4
class JekyllRedirectFrom::Generator < ::Jekyll::Generator
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#8
  def generate(site); end

  # Returns the value of attribute redirects.
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#6
  def redirects; end

  # Returns the value of attribute site.
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#6
  def site; end

  private

  # For every `redirect_from` entry, generate a redirect page
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#31
  def generate_redirect_from(doc); end

  # source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#39
  def generate_redirect_to(doc); end

  # source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#48
  def generate_redirects_json; end

  # @return [Boolean]
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#61
  def generate_redirects_json?; end

  # @return [Boolean]
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/generator.rb#57
  def redirectable_document?(doc); end

  class << self
    # source://jekyll/4.3.2/lib/jekyll/plugin.rb#24
    def inherited(const_); end
  end
end

# A stubbed layout for our default redirect template
# We cannot use the standard Layout class because of site.in_source_dir
#
# source://jekyll-redirect-from//lib/jekyll-redirect-from/layout.rb#6
class JekyllRedirectFrom::Layout < ::Jekyll::Layout
  # @return [Layout] a new instance of Layout
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/layout.rb#7
  def initialize(site); end
end

# source://jekyll-redirect-from//lib/jekyll-redirect-from/page_without_a_file.rb#4
class JekyllRedirectFrom::PageWithoutAFile < ::Jekyll::Page
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/page_without_a_file.rb#5
  def read_yaml(*_arg0); end
end

# Specialty page which implements the redirect path logic
#
# source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#5
class JekyllRedirectFrom::RedirectPage < ::Jekyll::Page
  include ::Jekyll::Filters::URLFilters

  # Overwrite the default read_yaml method since the file doesn't exist
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#36
  def read_yaml(_base, _name, _opts = T.unsafe(nil)); end

  # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#57
  def redirect_from; end

  # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#61
  def redirect_to; end

  # Helper function to set the appropriate path metadata
  #
  # from - the relative path to the redirect page
  # to   - the relative path or absolute URL to the redirect target
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#45
  def set_paths(from, to); end

  private

  # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#67
  def context; end

  class << self
    # Creates a new RedirectPage instance from a source path and redirect path
    #
    # site - The Site object
    # from - the (URL) path, relative to the site root to redirect from
    # to   - the relative path or URL which the page should redirect to
    #
    # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#19
    def from_paths(site, from, to); end

    # Creates a new RedirectPage instance from the path to the given doc
    #
    # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#26
    def redirect_from(doc, path); end

    # Creates a new RedirectPage instance from the doc to the given path
    #
    # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#31
    def redirect_to(doc, path); end
  end
end

# source://jekyll-redirect-from//lib/jekyll-redirect-from/redirect_page.rb#9
JekyllRedirectFrom::RedirectPage::DEFAULT_DATA = T.let(T.unsafe(nil), Hash)

# Module which can be mixed in to documents (and pages) to provide
# redirect_to and redirect_from helpers
#
# source://jekyll-redirect-from//lib/jekyll-redirect-from/redirectable.rb#6
module JekyllRedirectFrom::Redirectable
  # Returns an array representing the relative paths to other
  # documents which should be redirected to this document
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirectable.rb#19
  def redirect_from; end

  # Returns a string representing the relative path or URL
  # to which the document should be redirected
  #
  # source://jekyll-redirect-from//lib/jekyll-redirect-from/redirectable.rb#9
  def redirect_to; end
end

# source://jekyll-redirect-from//lib/jekyll-redirect-from/version.rb#4
JekyllRedirectFrom::VERSION = T.let(T.unsafe(nil), String)