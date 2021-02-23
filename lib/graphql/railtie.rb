# frozen_string_literal: true

module GraphQL
  class Railtie < Rails::Railtie
    config.before_configuration do
      # Bootsnap compile cache has similar expiration properties,
      # so we assume that if the user has bootsnap setup it's ok
      # to piggy back on it.
      if ::Object.const_defined?("Bootsnap::CompileCache::ISeq") && Bootsnap::CompileCache::ISeq.cache_dir
        Language::Parser.cache ||= Language::Cache.new(Pathname.new(Bootsnap::CompileCache::ISeq.cache_dir).join('graphql'))
      end
    end

    rake_tasks do
      # Defer this so that you only need the `parser` gem when you _run_ the upgrader
      def load_upgraders
        require_relative './upgrader/member'
        require_relative './upgrader/schema'
      end

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

          puts "Upgrade complete! Note that this is a best-effort approach, and may very well contain some bugs."
          puts "Don't forget to create the base objects. For example, you could run:"
          puts "\tbin/rake graphql:upgrade:create_base_objects[app/graphql]"
        end

        namespace :upgrade do
          task :create_base_objects, [:base_dir] do |t, args|
            unless (base_dir = args[:base_dir])
              fail 'You have to give me a directory where your GraphQL types live. ' \
                   'For example: `bin/rake graphql:upgrade:create_base_objects[app/graphql]`'
            end

            destination_file = File.join(base_dir, "types", "base_scalar.rb")
            unless File.exists?(destination_file)
              FileUtils.mkdir_p(File.dirname(destination_file))
              File.open(destination_file, 'w') do |f|
                f.puts "class Types::BaseScalar < GraphQL::Schema::Scalar\nend"
              end
            end

            destination_file = File.join(base_dir, "types", "base_input_object.rb")
            unless File.exists?(destination_file)
              FileUtils.mkdir_p(File.dirname(destination_file))
              File.open(destination_file, 'w') do |f|
                f.puts "class Types::BaseInputObject < GraphQL::Schema::InputObject\nend"
              end
            end

            destination_file = File.join(base_dir, "types", "base_enum.rb")
            unless File.exists?(destination_file)
              FileUtils.mkdir_p(File.dirname(destination_file))
              File.open(destination_file, 'w') do |f|
                f.puts "class Types::BaseEnum < GraphQL::Schema::Enum\nend"
              end
            end

            destination_file = File.join(base_dir, "types", "base_union.rb")
            unless File.exists?(destination_file)
              FileUtils.mkdir_p(File.dirname(destination_file))
              File.open(destination_file, 'w') do |f|
                f.puts "class Types::BaseUnion < GraphQL::Schema::Union\nend"
              end
            end

            destination_file = File.join(base_dir, "types", "base_interface.rb")
            unless File.exists?(destination_file)
              FileUtils.mkdir_p(File.dirname(destination_file))
              File.open(destination_file, 'w') do |f|
                f.puts "module Types::BaseInterface\n  include GraphQL::Schema::Interface\nend"
              end
            end

            destination_file = File.join(base_dir, "types", "base_object.rb")
            unless File.exists?(destination_file)
              File.open(destination_file, 'w') do |f|
                f.puts "class Types::BaseObject < GraphQL::Schema::Object\nend"
              end
            end
          end

          task :schema, [:schema_file] do |t, args|
            schema_file = args.schema_file
            load_upgraders
            upgrader = GraphQL::Upgrader::Schema.new File.read(schema_file)

            puts "- Transforming schema #{schema_file}"
            File.open(schema_file, 'w') { |f| f.write upgrader.upgrade }
          end

          task :member, [:member_file] do |t, args|
            member_file = args.member_file
            load_upgraders
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
