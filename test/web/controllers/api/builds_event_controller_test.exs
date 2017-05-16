defmodule AlloyCi.Web.Api.BuildsEventControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  import AlloyCi.Factory

  setup do
    {:ok, runner: insert(:runner)}
  end

  describe "request/4" do
    test "fetches a build, starts it and returns the correct data", %{runner: runner} do
      insert(:full_build)
      params = %{
        token: runner.token,
        info: %{
          name: "runner",
          version: "9",
          platform: "darwin",
          architecture: "amd64"
        }
      }

      expected_steps = [
        %{allow_failure: false, name: :script,
          script: ["mix deps.get", "mix test"],
          timeout: 3600, when: "on_success"}
      ]

      conn =
        build_conn()
        |> post("/api/v4/jobs/request", params)

      assert conn.status == 201
      assert conn.resp_body =~ "variables"
      assert conn.assigns.steps == expected_steps
      assert conn.assigns.status == "running"
      assert conn.assigns.runner_id == runner.id
    end

    test "returns 204 when there is no build", %{runner: runner} do
      conn =
        build_conn()
        |> post("/api/v4/jobs/request", %{token: runner.token, info: %{}})

      assert conn.status == 204
      assert conn.resp_body =~ "No Content"
    end

    test "returns 401 when wrong token" do
      conn =
        build_conn()
        |> post("/api/v4/jobs/request", %{token: "token-1"})

      assert conn.status == 401
      assert conn.resp_body =~ "Unauthorized"
    end
  end
end
