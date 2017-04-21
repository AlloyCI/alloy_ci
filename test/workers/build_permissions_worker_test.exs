defmodule AlloyCi.BuildPermissionsWorkerTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.Workers.BuildPermissionsWorker
  import AlloyCi.Factory
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup do
    HTTPoison.start
    {:ok, %{user: insert(:user)}}
  end

  test "creation of the correct project permissions", %{user: user} do
    project = insert(:project)
    insert(:empty_project_permission, user_id: user.id, repo_id: "14144680", project_id: project.id)
    new_user = insert(:user)

    use_cassette "repositories_list" do
      BuildPermissionsWorker.perform(new_user.id, "fake-token")
      new_user = new_user |> Repo.preload(:projects)

      assert Enum.member?(new_user.projects, project)
    end
  end
end
