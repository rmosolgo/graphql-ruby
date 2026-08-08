# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # **API:** public Shared methods for working with [Dataloader](rdoc-ref:Dataloader) inside GraphQL runtime objects.
      module HasDataloader
        # **Returns**
        #
        # - `GraphQL::Dataloader` — The dataloader for the currently-running query
        def dataloader
          context.dataloader
        end

        # A shortcut method for loading a key from a source.
        # Identical to `dataloader.with(source_class, *source_args).load(load_key)`
        #
        # **Parameters**
        #
        # - `source_class` (`Class<GraphQL::Dataloader::Source>`)
        # - `source_args` (`Array<Object>`) — Any extra parameters defined in `source_class`'s `initialize` method
        # - `load_key` (`Object`) — The key to look up using `def fetch`
        def dataload(source_class, *source_args, load_key)
          dataloader.with(source_class, *source_args).load(load_key)
        end

        # A shortcut method for loading many keys from a source.
        # Identical to `dataloader.with(source_class, *source_args).load_all(load_keys)`
        #
        # **Examples**
        #
        # **Example: field :score, Integer, resolve_batch: true**
        #
        # ```ruby
        # def self.score(posts)
        #   dataload_all(PostScoreSource, posts.map(&:id))
        # end
        # ```
        #
        # **Parameters**
        #
        # - `source_class` (`Class<GraphQL::Dataloader::Source>`)
        # - `source_args` (`Array<Object>`) — Any extra parameters defined in `source_class`'s `initialize` method
        # - `load_keys` (`Array<Object>`) — The keys to look up using `def fetch`
        def dataload_all(source_class, *source_args, load_keys)
          dataloader.with(source_class, *source_args).load_all(load_keys)
        end

        # Find an object with ActiveRecord via [Dataloader::ActiveRecordSource](rdoc-ref:Dataloader::ActiveRecordSource).
        #
        # **Parameters**
        #
        # - `model` (`Class<ActiveRecord::Base>`)
        # - `find_by_value` (`Object`) — Usually an `id`, might be another value if `find_by:` is also provided
        # - `find_by` (`Symbol, String`) — A column name to look the record up by. (Defaults to the model's primary key.)
        #
        # **Returns**
        #
        # - `ActiveRecord::Base, nil`
        #
        # **Examples**
        #
        # **Example: Finding a record by ID**
        #
        # ```ruby
        # dataload_record(Post, 5) # Like `Post.find(5)`, but dataloaded
        # ```
        #
        # **Example: Finding a record by another attribute**
        #
        # ```ruby
        # dataload_record(User, "matz", find_by: :handle) # Like `User.find_by(handle: "matz")`, but dataloaded
        # ```
        def dataload_record(model, find_by_value, find_by: nil)
          source = if find_by
            dataloader.with(Dataloader::ActiveRecordSource, model, find_by: find_by)
          else
            dataloader.with(Dataloader::ActiveRecordSource, model)
          end

          source.load(find_by_value)
        end

        # See [dataload_record](rdoc-ref:dataload_record) Like `dataload_record`, but accepts an Array of `find_by_values`
        def dataload_all_records(model, find_by_values, find_by: nil)
          source = if find_by
            dataloader.with(Dataloader::ActiveRecordSource, model, find_by: find_by)
          else
            dataloader.with(Dataloader::ActiveRecordSource, model)
          end
          source.load_all(find_by_values)
        end

        # Look up an associated record using a Rails association (via [Dataloader::ActiveRecordAssociationSource](rdoc-ref:Dataloader::ActiveRecordAssociationSource))
        #
        # **Parameters**
        #
        # - `association_name` (`Symbol`) — A `belongs_to` or `has_one` association. (If a `has_many` association is named here, it will be selected without pagination.)
        # - `record` (`ActiveRecord::Base`) — The object that the association belongs to.
        # - `scope` (`ActiveRecord::Relation`) — A scope to look up the associated record in
        #
        # **Returns**
        #
        # - `ActiveRecord::Base, nil` — The associated record, if there is one
        #
        # **Examples**
        #
        # **Example: Looking up a belongs_to on the current object**
        #
        # ```ruby
        # dataload_association(:parent) # Equivalent to `object.parent`, but dataloaded
        # ```
        #
        # **Example: Looking up an associated record on some other object**
        #
        # ```ruby
        # dataload_association(comment, :post) # Equivalent to `comment.post`, but dataloaded
        # ```
        def dataload_association(record = object, association_name, scope: nil)
          source = if scope
            dataloader.with(Dataloader::ActiveRecordAssociationSource, association_name, scope)
          else
            dataloader.with(Dataloader::ActiveRecordAssociationSource, association_name)
          end
          source.load(record)
        end

        # See [dataload_association](rdoc-ref:dataload_association) Like `dataload_assocation` but accepts an Array of records (required param)
        def dataload_all_associations(records, association_name, scope: nil)
          source = if scope
            dataloader.with(Dataloader::ActiveRecordAssociationSource, association_name, scope)
          else
            dataloader.with(Dataloader::ActiveRecordAssociationSource, association_name)
          end
          source.load_all(records)
        end
      end
    end
  end
end
