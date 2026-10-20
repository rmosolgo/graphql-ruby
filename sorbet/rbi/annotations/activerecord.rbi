# typed: true

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

module ActiveRecord::AttributeMethods::ClassMethods
  sig { returns(T::Array[String]) }
  def attribute_names; end
end

module ActiveRecord::AttributeMethods::Dirty
  sig { returns(ActiveSupport::HashWithIndifferentAccess) }
  def attributes_in_database; end

  sig { returns(T::Array[String]) }
  def changed_attribute_names_to_save; end

  sig { returns(ActiveSupport::HashWithIndifferentAccess) }
  def changes_to_save; end

  sig { returns(T::Boolean) }
  def has_changes_to_save?; end

  sig { returns(ActiveSupport::HashWithIndifferentAccess) }
  def saved_changes; end

  sig { returns(T::Boolean) }
  def saved_changes?; end
end

class ActiveRecord::Schema
  sig { params(info: T::Hash[T.untyped, T.untyped], blk: T.proc.bind(ActiveRecord::Schema).void).void }
  def self.define(info = nil, &blk); end
end

class ActiveRecord::Migration
  # @shim: Methods on migration are delegated to `SchemaStatements` using `method_missing`
  include ActiveRecord::ConnectionAdapters::SchemaStatements

  # @shim: Methods on migration are delegated to `DatabaseStatements` using `method_missing`
  include ActiveRecord::ConnectionAdapters::DatabaseStatements
end

# @version >= 7.2.0
module ActiveRecord::Assertions::QueryAssertions
  sig { type_parameters(:R).params(count: T.nilable(Integer), include_schema: T::Boolean, block: T.proc.returns(T.type_parameter(:R))).returns(T.type_parameter(:R)) }
  def assert_queries_count(count = nil, include_schema: false, &block); end

  sig { type_parameters(:R).params(include_schema: T::Boolean, block: T.proc.returns(T.type_parameter(:R))).returns(T.type_parameter(:R)) }
  def assert_no_queries(include_schema: false, &block); end

  sig { type_parameters(:R).params(match: T.any(String, Regexp), count: T.nilable(Integer), include_schema: T::Boolean, block: T.proc.returns(T.type_parameter(:R))).returns(T.type_parameter(:R)) }
  def assert_queries_match(match, count: nil, include_schema: false, &block); end

  sig { type_parameters(:R).params(match: T.any(String, Regexp), include_schema: T::Boolean, block: T.proc.returns(T.type_parameter(:R))).returns(T.type_parameter(:R)) }
  def assert_no_queries_match(match, include_schema: false, &block); end
end

# @version >= 7.2.0
class ActiveSupport::TestCase
  # @shim: Rails includes query assertions into ActiveSupport::TestCase from rails/test_help when ActiveRecord is loaded.
  include ActiveRecord::Assertions::QueryAssertions
end

class ActiveRecord::Base
  sig { returns(FalseClass) }
  def blank?; end

  # @shim: since `present?` is always true, `presence` always returns `self`
  sig { returns(T.self_type) }
  def presence; end

  sig { returns(TrueClass) }
  def present?; end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_initialize(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_find(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_touch(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.before_validation(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_validation(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.before_save(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.around_save(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_save(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.before_create(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.around_create(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_create(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.before_update(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.around_update(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_update(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.before_destroy(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.around_destroy(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_destroy(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_commit(*args, **options, &block); end

  sig { params(args: T.untyped, options: T.untyped, block: T.nilable(T.proc.bind(T.attached_class).params(record: T.attached_class).void)).void }
  def self.after_rollback(*args, **options, &block); end
end

class ActiveRecord::Relation
  Elem = type_member(:out) { { fixed: T.untyped } }

  sig { returns(T::Boolean) }
  def blank?; end

  sig { abstract.params(blk: T.proc.params(arg0: Elem).returns(BasicObject)).returns(T.untyped) }
  sig { abstract.returns(T::Enumerator[Elem]) }
  def each(&blk); end
end

module ActiveRecord::Core
  sig { params(comparison_object: T.anything).returns(T::Boolean) }
  def ==(comparison_object); end
end

module ActiveRecord::Persistence
  sig { type_parameters(:Klass).params(klass: T::Class[T.type_parameter(:Klass)]).returns(T.type_parameter(:Klass)) }
  def becomes(klass); end

  sig { type_parameters(:Klass).params(klass: T::Class[T.type_parameter(:Klass)]).returns(T.type_parameter(:Klass)) }
  def becomes!(klass); end

  sig { returns(T::Boolean) }
  def destroyed?; end

  sig { returns(T::Boolean) }
  def new_record?; end

  sig { returns(T::Boolean) }
  def persisted?; end

  sig { returns(T::Boolean) }
  def previously_new_record?; end

  sig { returns(T::Boolean) }
  def previously_persisted?; end
end
