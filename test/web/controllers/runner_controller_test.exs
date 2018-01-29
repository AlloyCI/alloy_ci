defmodule AlloyCi.Web.RunnerControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.Runner
  import AlloyCi.Factory

  @valid_attrs %{run_untagged: true, tags: ["ruby", "elixir"]}

  setup do
    {user, project} = insert(:project) |> with_user_return_both()
    runner = insert(:runner, project_id: project.id)

    {:ok, %{runner: runner, user: user}}
  end

  test "shows chosen resource", %{user: user, runner: runner} do
    conn =
      user
      |> guardian_login(:access)
      |> get(runner_path(build_conn(), :show, runner))

    assert html_response(conn, 200) =~ "Runner Settings"
  end

  test "updates chosen resource and redirects when data is valid", %{user: user, runner: runner} do
    conn =
      user
      |> guardian_login(:access)
      |> put(runner_path(build_conn(), :update, runner), runner: @valid_attrs)

    assert redirected_to(conn) == runner_path(conn, :show, runner)
  end

  test "deletes chosen resource", %{user: user, runner: runner} do
    conn =
      user
      |> guardian_login(:access)
      |> delete(runner_path(build_conn(), :delete, runner))

    assert redirected_to(conn) == project_path(conn, :show, runner.project_id)
    refute Repo.get(Runner, runner.id)
  end
end
