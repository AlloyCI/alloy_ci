defmodule AlloyCi.RunnersTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Runners, Repo}
  import AlloyCi.Factory

  setup do
    build = insert(:full_build)

    {:ok, %{build: build}}
  end

  describe "all/1" do
    test "it retruns all projects" do
      insert(:runner)
      {runners, _} = Runners.all(%{page: 1})

      assert Enum.count(runners) == 1
    end
  end

  describe "create/1" do
    test "it creates a global runner" do
      params = %{
        "token" => Application.get_env(:alloy_ci, :runner_registration_token),
        "description" => "test runner",
        "info" => %{"name" => "test"},
        "tag_list" => "elixir,postgres,linux",
        "locked" => false,
        "run_untagged" => false
      }

      result = Runners.create(params)
      runner = Runners.get(result.id)

      assert result != nil
      assert result.locked == false
      assert result.global == true
      assert result.tags == ~w(elixir postgres linux)
      assert runner == result
    end

    test "it creates a project specific runner" do
      project = insert(:project)

      params = %{
        "token" => project.token,
        "description" => "test runner",
        "info" => %{"name" => "test"},
        "tag_list" => "elixir,postgres,linux",
        "locked" => false,
        "run_untagged" => false
      }

      result = Runners.create(params)

      assert result != nil
      assert result.global == false
      assert result.tags == ~w(elixir postgres linux)
      assert result.project_id == project.id
    end
  end

  describe "delete_by/1" do
    test "it deletes a runner by it's token" do
      runner = insert(:runner)
      assert {:ok, _} = Runners.delete_by(token: runner.token)
    end

    test "it deletes a runner by it's id" do
      runner = insert(:runner)
      assert {:ok, _} = Runners.delete_by(id: runner.id)
    end
  end

  describe "get_by/1" do
    test "it gets the correct runner" do
      runner = insert(:runner)
      result = Runners.get_by(token: runner.token)

      assert result.id == runner.id
    end

    test "it returns nil when runner not found" do
      result = Runners.get_by(token: "invalid-token")

      assert result == nil
    end
  end

  describe "register_job/1" do
    test "it processes and starts any correct build", %{build: build} do
      runner = insert(:runner)
      {:ok, result} = Runners.register_job(runner)

      assert result.id == build.id
      assert result.status == "running"
      assert result.runner_id == runner.id
    end

    test "it processes and starts tagged builds that match the runner's tags" do
      runner = insert(:runner, tags: ~w(ruby elixir), run_untagged: false)
      build = insert(:full_build, tags: ~w(elixir))

      {:ok, result} = Runners.register_job(runner)

      assert result.id == build.id
      assert result.status == "running"
      assert result.runner_id == runner.id
    end

    test "it processes and starts tagged builds first even if the runner can run untagged" do
      runner = insert(:runner, tags: ~w(ruby elixir))
      build = insert(:full_build, tags: ~w(elixir))
      {:ok, result} = Runners.register_job(runner)

      assert result.id == build.id
      assert result.status == "running"
      assert result.runner_id == runner.id
    end

    test "it processes and starts any build even if the runner is tagged", %{build: build} do
      runner = insert(:runner, tags: ~w(ruby elixir))
      {:ok, result} = Runners.register_job(runner)

      assert result.id == build.id
      assert result.status == "running"
      assert result.runner_id == runner.id
    end

    test "it processes and starts a project's specific build", %{build: build} do
      runner = insert(:runner, project_id: build.project_id)
      {:ok, result} = Runners.register_job(runner)

      assert result.id == build.id
      assert result.status == "running"
      assert result.runner_id == runner.id
    end

    test "it returns correct status when no build is found", %{build: build} do
      runner = insert(:runner)
      Repo.delete!(build)
      assert {:no_build, result} = Runners.register_job(runner)

      assert result == nil
    end

    test "it returns correct status when build is tagged, but runner is not", %{build: build} do
      runner = insert(:runner)
      Repo.delete!(build)
      insert(:full_build, tags: ~w(elixir))
      assert {:no_build, result} = Runners.register_job(runner)

      assert result == nil
    end
  end
end
