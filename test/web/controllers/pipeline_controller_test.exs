defmodule AlloyCi.Web.PipelineControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  import AlloyCi.Factory

  setup do
    project = insert(:project)
    pipeline = insert(:clean_pipeline, project: project)
    user = insert(:user)
    insert(:clean_project_permission, project: project, user: user)

    {:ok, %{project: project, pipeline: pipeline, user: user}}
  end

  test "it shows chosen pipeline", %{project: project, pipeline: pipeline, user: user} do
    conn =
      user
      |> guardian_login(:access)
      |> get("/projects/#{project.id}/pipelines/#{pipeline.id}")

    assert html_response(conn, 200) =~ "#{pipeline.commit["message"]}"
  end

  test "it redirects if user cannot access pipeline", %{project: project, pipeline: pipeline} do
    conn =
      :user
      |> insert()
      |> guardian_login(:access)
      |> get("/projects/#{project.id}/pipelines/#{pipeline.id}")

    assert html_response(conn, 302) =~ "redirected"
  end
end
