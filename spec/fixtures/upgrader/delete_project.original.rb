# frozen_string_literal: true

module Platform
  module Mutations
    DeleteProject = GraphQL::Relay::Mutation.define do
      name "DeleteProject"
      description "Deletes a project."

      minimum_accepted_scopes ["public_repo"]

      input_field :projectId, !types.ID, "The Project ID to update."
      return_field :owner, !Interfaces::ProjectOwner, "The repository or organization the project was removed from."

      resolve ->(root_obj, inputs, context) do
        project =  Platform::Helpers::NodeIdentification.typed_object_from_id(
          [Objects::Project], inputs[:projectId], context
        )

        context[:permission].can_modify?("DeleteProject", project).sync
        context[:abilities].authorize_content(:project, :destroy, owner: project.owner)

        project.enqueue_delete(actor: context[:viewer])

        { owner: project.owner }
      end
    end
  end
end
