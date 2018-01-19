defmodule AlloyCi.ProjectsTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Projects, Repo}
  import AlloyCi.ProjectPermission, only: [existing_ids: 0]
  import AlloyCi.Factory

  setup do
    user = insert(:user_with_project)
    [project | _] = (user |> Repo.preload(:projects)).projects

    {:ok, %{project: project, user: user}}
  end

  describe "all/1" do
    test "it retruns all projects" do
      insert(:project)
      {projects, _} = Projects.all(%{page: 1})

      assert Enum.count(projects) == 2
    end
  end

  describe "delete_by" do
    test "delete_by/2 deletes the project if it belongs to the user", %{
      project: project,
      user: user
    } do
      assert {:ok, _} = Projects.delete_by(project.id, user)
      project = Projects.get(project.id)

      assert project == nil
    end

    test "delete_by/1 deletes the project", %{project: project} do
      assert {:ok, _} = Projects.delete_by(id: project.id)
      project = Projects.get(project.id)

      assert project == nil
    end
  end

  describe "repo_and_project/2" do
    test "it returns a tuple of {repo_id, project_id}", %{project: project} do
      {:ok, {repo_id, project_id}} = Projects.repo_and_project(project.repo_id, existing_ids())

      assert repo_id == project.repo_id
      assert project_id == project.id
    end
  end
end
