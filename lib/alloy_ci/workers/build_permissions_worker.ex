defmodule AlloyCi.Workers.BuildPermissionsWorker do
  @moduledoc """
  This worker takes care of creating the project permissions for newly created
  users. If the user has access to a project that has already been added to
  AlloyCI, it will be added to the list of projects to which they already have
  access.
  """
  alias AlloyCi.{Repo, ProjectPermission}
  import AlloyCi.ProjectPermission, only: [existing_ids: 0]

  def perform(user_id, token) do
    client = Tentacat.Client.new(%{access_token: token})
    repo_ids =
      client
      |> Tentacat.Repositories.list_mine
      |> Enum.map(&(&1["id"]))

    permission_ids = MapSet.intersection(MapSet.new(repo_ids), MapSet.new(existing_ids()))

    Repo.transaction(fn ->
      Enum.each(permission_ids, fn(id) ->
        project_id = (Repo.get_by(ProjectPermission, repo_id: id)).project_id
        params = %{user_id: user_id, project_id: project_id, repo_id: id}
        %ProjectPermission{}
        |> ProjectPermission.changeset(params)
        |> Repo.insert()
      end)
    end)
  end
end
