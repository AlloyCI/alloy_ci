defmodule AlloyCi.Web.ProjectControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.Project
  import AlloyCi.Factory

  @valid_attrs %{
    owner: "some_owner",
    owner_id: 42,
    name: "some content",
    private: true,
    repo_id: 69,
    tags: ["one", "two"]
  }
  @invalid_attrs %{repo_id: nil}

  setup do
    user = insert(:user_with_project)
    insert(:github_auth, user: user)
    insert(:installation, target_id: 42)
    {:ok, %{user: user}}
  end

  test "lists all entries on index", %{user: user} do
    conn =
      user
      |> guardian_login(:access)
      |> get("/projects")

    assert html_response(conn, 200) =~ "Your projects"
  end

  test "creates resource and redirects when data is valid", %{user: user} do
    conn =
      user
      |> guardian_login(:access)
      |> post(project_path(build_conn(), :create), project: @valid_attrs)

    project = Project |> last |> Repo.one()

    assert redirected_to(conn) == project_path(conn, :show, project.id)
    assert Repo.get(Project, project.id)

    permission = AlloyCi.ProjectPermission |> last |> Repo.one()
    assert permission.repo_id == 69
    assert permission.user_id == user.id
  end

  test "does not create resource and renders errors when data is invalid", %{user: user} do
    conn =
      user
      |> guardian_login(:access)
      |> post(project_path(build_conn(), :create), project: @invalid_attrs)

    assert redirected_to(conn) == project_path(conn, :index)
  end

  test "shows chosen resource", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects

    conn =
      user
      |> guardian_login(:access)
      |> get(project_path(build_conn(), :show, project))

    assert html_response(conn, 200) =~ project.name
  end

  test "renders form for editing chosen resource", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects

    conn =
      user
      |> guardian_login(:access)
      |> get(project_path(build_conn(), :edit, project))

    assert html_response(conn, 200) =~ "Project Settings"
  end

  test "updates chosen resource and redirects when data is valid", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects

    conn =
      user
      |> guardian_login(:access)
      |> put(project_path(build_conn(), :update, project), project: @valid_attrs)

    assert redirected_to(conn) == project_path(conn, :edit, project)
    assert Repo.get(Project, project.id)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects

    conn =
      user
      |> guardian_login(:access)
      |> put(project_path(build_conn(), :update, project), project: @invalid_attrs)

    assert html_response(conn, 200) =~ "Project Settings"
  end

  test "deletes chosen resource", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects

    conn =
      user
      |> guardian_login(:access)
      |> delete(project_path(build_conn(), :delete, project))

    assert redirected_to(conn) == project_path(conn, :index)
    refute Repo.get(Project, project.id)
  end
end
