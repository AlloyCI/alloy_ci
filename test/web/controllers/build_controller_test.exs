defmodule AlloyCi.Web.BuildControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.{Project, Repo}
  import AlloyCi.Factory

  setup do
    project = insert(:project, private: true)
    pipeline = insert(:clean_pipeline, project: project)
    build = insert(:build, trace: "build trace", pipeline: pipeline, project: project)
    user = insert(:user)
    insert(:clean_project_permission, project: project, user: user)

    {:ok, %{project: project, build: build, user: user}}
  end

  test "it responds with the chosen build trace", %{project: project, build: build, user: user} do
    conn =
      user
      |> guardian_login(:access)
      |> get("/projects/#{project.id}/builds/#{build.id}")

    assert json_response(conn, 200) == %{"trace" => build.trace}
  end

  test "it redirects if user cannot access pipeline", %{project: project, build: build} do
    conn =
      :user
      |> insert()
      |> guardian_login(:access)
      |> get("/projects/#{project.id}/builds/#{build.id}")

    assert json_response(conn, 404) == %{"trace" => "Error: Build not found"}
  end

  test "it responds with the chose trace if project is public", %{project: project, build: build} do
    project |> Project.changeset(%{private: false}) |> Repo.update()

    conn =
      :user
      |> insert()
      |> guardian_login(:access)
      |> get("/projects/#{project.id}/builds/#{build.id}")

    assert json_response(conn, 200) == %{"trace" => build.trace}
  end
end
