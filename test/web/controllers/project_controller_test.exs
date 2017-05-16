defmodule AlloyCi.Web.ProjectControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.Project
  import AlloyCi.Factory
  import Mock

  @valid_attrs %{owner: "some_owner", name: "some content", private: true, repo_id: 69, tags: ["one", "two"]}
  @invalid_attrs %{repo_id: nil}

  setup do
    HTTPoison.start
    {:ok, %{user: insert(:user_with_project)}}
  end

  test "lists all entries on index", %{user: user} do
    conn =
      user
      |> guardian_login(:access)
      |> get("/projects")

    assert html_response(conn, 200) =~ "Your projects"
  end

  test "renders GitHub repos to add", %{user: user} do
    with_mock AlloyCi.Github, [repos_for: fn(_) -> Poison.decode!(File.read!("test/fixtures/responses/repositories_list.json")) end] do
      conn =
        user
        |> guardian_login(:access)
        |> get("/projects/new")

      response = html_response(conn, 200)

      assert response =~ "Add your repos"
      assert response =~ "pacman"
      assert response =~ "Elixir berlin meetup kata challenge"
    end
  end

  test "creates resource and redirects when data is valid", %{user: user} do
    conn =
      user
      |> guardian_login(:access)
      |> post(project_path(build_conn(), :create), project: @valid_attrs)

    project = Project |> last |> Repo.one

    assert redirected_to(conn) == project_path(conn, :show, project.id)
    assert Repo.get_by(Project, @valid_attrs)

    permission = AlloyCi.ProjectPermission |> last |> Repo.one
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

  # test "renders page not found when id is nonexistent", %{user: user} do
  #   assert_error_sent 404, fn ->
  #     get conn, project_path(conn, :show, -1)
  #   end
  # end

  test "renders form for editing chosen resource", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects
    conn =
      user
      |> guardian_login(:access)
      |> get(project_path(build_conn(), :edit, project))

    assert html_response(conn, 200) =~ "Edit project"
  end

  test "updates chosen resource and redirects when data is valid", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects
    conn =
      user
      |> guardian_login(:access)
      |> put(project_path(build_conn(), :update, project), project: @valid_attrs)

    assert redirected_to(conn) == project_path(conn, :show, project)
    assert Repo.get_by(Project, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{user: user} do
    [project | _] = (user |> Repo.preload(:projects)).projects
    conn =
      user
      |> guardian_login(:access)
      |> put(project_path(build_conn(), :update, project), project: @invalid_attrs)

    assert html_response(conn, 200) =~ "Edit project"
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
