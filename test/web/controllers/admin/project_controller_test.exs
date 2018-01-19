defmodule AlloyCi.Web.Admin.ProjectControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.Project
  import AlloyCi.Factory

  setup do
    {:ok, %{user: insert(:user_with_project)}}
  end

  test "lists all entries on index", %{user: user} do
    conn =
      user
      |> guardian_login(:token, key: :admin)
      |> get("/admin/projects")

    assert html_response(conn, 200) =~ "Projects"
  end

  test "shows chosen resource", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects

    conn =
      user
      |> guardian_login(:token, key: :admin)
      |> get(admin_project_path(build_conn(), :show, project))

    assert html_response(conn, 200) =~ project.name
  end

  test "deletes chosen resource", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects

    conn =
      user
      |> guardian_login(:token, key: :admin)
      |> delete(admin_project_path(build_conn(), :delete, project))

    assert redirected_to(conn) == admin_project_path(conn, :index)
    refute Repo.get(Project, project.id)
  end
end
