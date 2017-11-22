# frozen_string_literal: true

require_relative './upgrader/member'

module GraphQL
  class Railtie < Rails::Railtie
    rake_tasks do
      namespace :graphql do
        task :upgrade, [:dir] do |t, args|
          unless (dir = args[:dir])
            fail 'You have to give me a directory where your GraphQL schema and types live. ' \
             'For example: `bin/rake graphql:upgrade[app/graphql/**/*]`'
          end

          Dir[dir].each do |file|
            # Members (types, interfaces, etc.)
            if file =~ /.*_(type|interface|enum|union|)\.rb$/
              upgrader = GraphQL::Upgrader::Member.new File.read(file)
              next unless upgrader.upgradeable?

              puts "- Transforming #{file}"
              File.open(file, 'w') { |f| f.write upgrader.upgrade }
            end
          end
        end
      end
    end
  end
end

