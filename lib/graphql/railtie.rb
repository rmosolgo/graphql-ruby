# frozen_string_literal: true

require_relative './upgrader/member'

module GraphQL
  class Railtie < Rails::Railtie
    rake_tasks do
      namespace :graphql do
        task :update, [:dir] do |t, args|
          unless (dir = args[:dir])
            fail 'You have to give me a directory where your GraphQL schema and types live. ' \
             'For example: `bin/rake graphql:update[app/graphql/**/*]`'
          end

          Dir[dir].each do |file|
            # Members (types, interfaces, etc.)
            if file =~ /.*_(type|interface|enum|union|)\.rb$/
              transformer = GraphQL::Upgrader::Member.new File.read(file)
              next unless transformer.transformable?

              puts "- Transforming #{file}"
              File.open(file, 'w') { |f| f.write transformer.transform }
            end
          end
        end
      end
    end
  end
end

