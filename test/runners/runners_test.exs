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

  describe "create/1" do
    test "it creates a global runner" do
      params = %{
        "token" => Application.get_env(:alloy_ci, :runner_registration_token),
        "description" => "test runner",
        "info" => %{"name" => "test"}
      }

      result = Runners.create(params)

      assert result != nil
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

  describe "get_by_token/1" do
    test "it gets the correct runner" do
      runner = insert(:runner)
      result = Runners.get_by_token(runner.token)

      assert result.id == runner.id
    end

    test "it returns nil when runner not found" do
      result = Runners.get_by_token("invalid-token")

      assert result == nil
    end
  end

  describe "register_job/1" do
    test "it processes and starts the correct build", %{build: build} do
      runner = insert(:runner)
      {:ok, result} = Runners.register_job(runner)

      assert result.id == build.id
      assert result.status == "running"
      assert result.runner_id == runner.id
    end

    test "it returns correct status when no build is found", %{build: build} do
      runner = insert(:runner)
      Repo.delete!(build)
      {:no_build, result} = Runners.register_job(runner)

      assert result == nil
    end
  end
end
