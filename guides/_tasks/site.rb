# frozen_string_literal: true
require "yard"

namespace :site do
  desc "View the documentation site locally"
  task serve: [:build_doc] do
    require "jekyll"
    options = {
      "source"      => File.expand_path("guides"),
      "destination" => File.expand_path("guides/_site"),
      "watch"       => true,
      "serving"     => true
    }
    # Generate the site in server mode.
    puts "Running Jekyll..."
    Jekyll::Commands::Build.process(options)
    Jekyll::Commands::Serve.process(options)
  end

  desc "Commit the local site to the gh-pages branch and publish to GitHub Pages"
  task publish: [:build_doc, :update_search_index] do
    # Ensure the gh-pages dir exists so we can generate into it.
    puts "Checking for gh-pages dir..."
    unless File.exist?("./gh-pages")
      puts "Creating gh-pages dir..."
      sh "git clone git@github.com:rmosolgo/graphql-ruby gh-pages"
    end

    # Ensure latest gh-pages branch history.
    Dir.chdir("gh-pages") do
      sh "git checkout gh-pages"
      sh "git pull origin gh-pages"
    end

    # Proceed to purge all files in case we removed a file in this release.
    puts "Cleaning gh-pages directory..."
    purge_exclude = [
      'gh-pages/.',
      'gh-pages/..',
      'gh-pages/.git',
      'gh-pages/.gitignore',
    ]
    FileList["gh-pages/{*,.*}"].exclude(*purge_exclude).each do |path|
      sh "rm -rf #{path}"
    end

    # Copy site to gh-pages dir.
    puts "Building site into gh-pages branch..."
    ENV['JEKYLL_ENV'] = 'production'
    require "jekyll"
    Jekyll::Commands::Build.process({
      "source"       => File.expand_path("guides"),
      "destination"  => File.expand_path("gh-pages"),
      "sass"         => { "style" => "compressed" }
    })

    File.write('gh-pages/.nojekyll', "Prevent GitHub from running Jekyll")

    # Commit and push.
    puts "Committing and pushing to GitHub Pages..."
    sha = `git rev-parse HEAD`.strip
    Dir.chdir('gh-pages') do
      sh "git add ."
      sh "git commit --allow-empty -m 'Updating to #{sha}.'"
      sh "git push origin gh-pages"
    end
    puts 'Done.'
  end

  YARD::Rake::YardocTask.new(:prepare_yardoc)

  task build_doc: :prepare_yardoc do
    require_relative "../../lib/graphql/version"

    def to_rubydoc_url(path)
      "http://www.rubydoc.info/gems/graphql/#{GraphQL::VERSION}/" + path
        .gsub("::", "/")                        # namespaces
        .sub(/#(.+)$/, "#\\1-instance_method")  # instance methods
        .sub(/\.(.+)$/, "#\\1-class_method")    # class methods
    end

    DOC_TEMPLATE = <<-PAGE
---
layout: doc_stub
search: true
title: %{title}
url: %{url}
rubydoc_url: %{url}
---

%{documentation}
PAGE

    puts "Preparing YARD docs @ v#{GraphQL::VERSION} for search index..."
    registry = YARD::Registry.load!(".yardoc")
    files_target = "guides/yardoc"
    FileUtils.rm_rf(files_target)
    FileUtils.mkdir_p(files_target)

    # Get docs for all classes and modules
    docs = registry.all(:class, :module)
    docs.each do |code_object|
      begin
        # Skip private classes and modules
        if code_object.visibility == :private
          next
        end
        rubydoc_url = to_rubydoc_url(code_object.path)
        page_content = DOC_TEMPLATE % {
          title: code_object.path,
          url: rubydoc_url,
          documentation: code_object.format.gsub(/-{2,}/, " ").gsub(/^\s+/, ""),
        }

        filename = code_object.path.gsub(/\W+/, "_")
        filepath = "guides/yardoc/#{filename}.md"
        File.write(filepath, page_content)
      rescue StandardError => err
        puts "Error on: #{code_object.path}"
        puts err
        puts err.backtrace
      end
    end
    puts "Wrote #{docs.size} YARD docs to #{files_target}."
  end

  task :update_search_index do
    if !ENV["ALGOLIA_API_KEY"]
      warn("Can't update search index without ALGOLIA_API_KEY; Search will be out-of-date.")
    else
      system("bundle exec jekyll algolia push --source=./guides")
    end
  end
end
