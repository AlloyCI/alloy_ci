defmodule AlloyCi.Web.Api.BuildsEventControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.Builds
  import AlloyCi.Factory

  setup do
    runner = insert(:runner)
    params = %{
      info: %{
        name: "runner",
        version: "9",
        platform: "darwin",
        architecture: "amd64"
      }
    }
    {:ok, %{runner: runner, params: params}}
  end

  describe "request/4" do
    test "fetches a build, starts it and returns the correct data", %{runner: runner, params: params} do
      insert(:full_build)
      params = Map.put(params, :token, runner.token)

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

  describe "update/4" do
    test "it updates the state of the build",  %{params: params} do
      build = insert(:full_build, status: "running")
      params = Map.merge(params, %{state: "success", token: build.token})

      conn =
        build_conn()
        |> put("/api/v4/jobs/#{build.id}", params)

      {:ok, build} = Builds.get_by(build.id, build.token)

      assert conn.status == 200
      assert conn.resp_body =~ "OK"
      assert build.status == "success"
    end
  end

  describe "trace/4" do
    test "it appends to the job's trace" do
      build = insert(:full_build, status: "running")

      raw_params =
        "\x1b[0KRunning with gitlab-ci-multi-runner 9.1.1 (6104325) on localhost.lan (OFdlS21H)
        \x1b[0;m\x1b[0KUsing Docker executor with image elixir:latest ...
        \x1b[0;m"

      conn =
        build_conn()
        |> put_req_header("job-token", build.token)
        |> put_req_header("content-type", "text/plain")
        |> patch("/api/v4/jobs/#{build.id}/trace", raw_params)

      {:ok, build} = Builds.get_by(build.id, build.token)

      assert conn.status == 202
      assert build.trace != nil
    end
  end
end
