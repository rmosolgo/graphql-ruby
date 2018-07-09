# frozen_string_literal: true

module Platform
  module Mutations
    class DeleteProject < Mutations::BaseMutation
      description "Deletes a project."

      minimum_accepted_scopes ["public_repo"]

      argument :project_id, ID, "The Project ID to update.", required: true
      field :owner, Interfaces::ProjectOwner, "The repository or organization the project was removed from.", null: false

      def resolve(**inputs)
        project =  Platform::Helpers::NodeIdentification.typed_object_from_id(
          [Objects::Project], inputs[:project_id], context
        )

        context[:permission].can_modify?("DeleteProject", project).sync
        context[:abilities].authorize_content(:project, :destroy, owner: project.owner)

        project.enqueue_delete(actor: context[:viewer])

        { owner: project.owner }
      end
    end
  end
end
