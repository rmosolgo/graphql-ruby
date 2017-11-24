# frozen_string_literal: true

require_relative './upgrader/member'
require_relative './upgrader/schema'

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
              Rake::Task["graphql:upgrade:member"].execute(Struct.new(:member_file).new(file))
            end
          end
        end

        namespace :upgrade do
          task :create_base_objects, [:base_dir] do |t, args|
            base_dir = args.base_dir

            destination_file = File.join(base_dir, "types", "base_enum.rb")
            unless File.exists?(destination_file)
              FileUtils.mkdir_p(File.dirname(destination_file))
              File.open(destination_file, 'w') do |f|
                f.write "class Types::BaseEnum < GraphQL::Schema::Enum; end"
              end
            end

            destination_file = File.join(base_dir, "types", "base_union.rb")
            unless File.exists?(destination_file)
              FileUtils.mkdir_p(File.dirname(destination_file))
              File.open(destination_file, 'w') do |f|
                f.write "class Types::BaseUnion < GraphQL::Schema::Union; end"
              end
            end

            destination_file = File.join(base_dir, "types", "base_interface.rb")
            unless File.exists?(destination_file)
              FileUtils.mkdir_p(File.dirname(destination_file))
              File.open(destination_file, 'w') do |f|
                f.write "class Types::BaseInterface < GraphQL::Schema::Interface; end"
              end
            end

            destination_file = File.join(base_dir, "types", "base_object.rb")
            unless File.exists?(destination_file)
              File.open(destination_file, 'w') do |f|
                f.write "class Types::BaseObject < GraphQL::Schema::Object; end"
              end
            end
          end

          task :schema, [:schema_file] do |t, args|
            schema_file = args.schema_file

            upgrader = GraphQL::Upgrader::Schema.new File.read(schema_file)

            puts "- Transforming schema #{schema_file}"
            File.open(schema_file, 'w') { |f| f.write upgrader.upgrade }
          end

          task :member, [:member_file] do |t, args|
            member_file = args.member_file

            upgrader = GraphQL::Upgrader::Member.new File.read(member_file)
            next unless upgrader.upgradeable?

            puts "- Transforming member #{member_file}"
            File.open(member_file, 'w') { |f| f.write upgrader.upgrade }
          end
        end
      end
    end
  end
end

