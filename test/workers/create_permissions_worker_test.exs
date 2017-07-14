defmodule AlloyCi.CreatePermissionsWorkerTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.Workers.CreatePermissionsWorker
  import AlloyCi.Factory

  setup do
    {:ok, %{user: insert(:user)}}
  end

  test "creation of the correct project permissions", %{user: user} do
    project = insert(:project)
    insert(:clean_project_permission, user_id: user.id, repo_id: "14144680", project_id: project.id)
    new_user = insert(:user)

    CreatePermissionsWorker.perform({new_user.id, "fake-token"})
    new_user = new_user |> Repo.preload(:projects)

    assert Enum.member?(new_user.projects, project)
  end
end
