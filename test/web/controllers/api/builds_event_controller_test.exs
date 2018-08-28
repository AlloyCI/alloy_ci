defmodule AlloyCi.Web.Api.BuildsEventControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.{Artifact, Builds}
  import AlloyCi.Factory

  setup do
    runner = insert(:runner)

    params = %{
      info: %{
        name: "runner",
        version: "1.0",
        platform: "darwin",
        architecture: "amd64"
      }
    }

    {:ok, %{runner: runner, params: params}}
  end

  describe "request/4" do
    test "fetches a build with named dependencies, starts it and returns the correct data", %{
      runner: runner,
      params: params
    } do
      pipeline = insert(:pipeline)

      dependent =
        insert(
          :build,
          status: "success",
          pipeline: pipeline,
          project: pipeline.project,
          artifacts: %{"paths" => ["alloy_ci.tar.gz"]},
          stage_idx: 0
        )

      {:ok, _} =
        insert(:artifact, build: dependent)
        |> Artifact.changeset(%{
          file: %Plug.Upload{path: ".alloy-ci.yml", filename: ".alloy-ci.yml"}
        })
        |> Repo.update()

      insert(
        :build,
        status: "success",
        pipeline: pipeline,
        project: pipeline.project,
        artifacts: %{"paths" => ["alloy_ci.zip"]},
        stage_idx: 0
      )

      build =
        insert(:full_build, pipeline: pipeline, project: pipeline.project, deps: [dependent.name])

      params = Map.put(params, :token, runner.token)

      expected_steps = [
        %{
          allow_failure: false,
          name: :script,
          script: ["mix deps.get", "mix test"],
          timeout: 3600,
          when: "on_success"
        }
      ]

      conn =
        build_conn()
        |> post("/api/v4/jobs/request", params)

      assert conn.status == 201
      assert conn.resp_body =~ "variables"
      assert conn.assigns.steps == expected_steps

      assert conn.assigns.dependencies == [
               %{
                 id: dependent.id,
                 name: dependent.name,
                 token: dependent.token,
                 artifacts_file: %{filename: ".alloy-ci.yml", size: 2500}
               }
             ]

      assert conn.assigns.status == "running"
      assert conn.assigns.runner_id == runner.id

      build = Builds.get(build.id)

      assert build.started_at != nil
    end

    test "fetches a build with specific dependencies, starts it and returns the correct data", %{
      runner: runner,
      params: params
    } do
      insert(:full_build, deps: [])
      params = Map.put(params, :token, runner.token)

      expected_steps = [
        %{
          allow_failure: false,
          name: :script,
          script: ["mix deps.get", "mix test"],
          timeout: 3600,
          when: "on_success"
        }
      ]

      conn =
        build_conn()
        |> post("/api/v4/jobs/request", params)

      assert conn.status == 201
      assert conn.resp_body =~ "variables"
      assert conn.assigns.steps == expected_steps
      assert conn.assigns.dependencies == []
      assert conn.assigns.status == "running"
      assert conn.assigns.runner_id == runner.id
    end

    test "fetches an extended build, starts it and returns the correct data", %{
      runner: runner,
      params: params
    } do
      build = insert(:extended_build)

      dependent =
        insert(
          :build,
          status: "success",
          pipeline: build.pipeline,
          project: build.project,
          artifacts: %{"paths" => ["alloy_ci.tar.gz"]},
          stage_idx: 0
        )

      {:ok, _} =
        insert(:artifact, build: dependent)
        |> Artifact.changeset(%{
          file: %Plug.Upload{path: ".alloy-ci.yml", filename: ".alloy-ci.yml"}
        })
        |> Repo.update()

      params = Map.put(params, :token, runner.token)

      expected_services = [
        %{
          "alias" => "post",
          "command" => ["/bin/sh"],
          "entrypoint" => ["/bin/sh"],
          "name" => "postgres:latest"
        }
      ]

      conn =
        build_conn()
        |> post("/api/v4/jobs/request", params)

      assert conn.status == 201
      assert conn.resp_body =~ "variables"
      assert conn.assigns.services == expected_services

      assert conn.assigns.dependencies == [
               %{
                 id: dependent.id,
                 name: dependent.name,
                 token: dependent.token,
                 artifacts_file: %{filename: ".alloy-ci.yml", size: 2500}
               }
             ]

      assert conn.assigns.artifacts == %{
               "paths" => ["alloy_ci.tar.gz", "_build/prod/lib/alloy_ci"]
             }

      assert conn.assigns.status == "running"
      assert conn.assigns.image == %{"name" => "elixir:latest", "entrypoint" => ["/bin/bash"]}
      assert conn.assigns.runner_id == runner.id
    end

    test "returns 204 when there is no build", %{runner: runner} do
      conn =
        build_conn()
        |> post("/api/v4/jobs/request", %{token: runner.token, info: %{}})

      assert conn.status == 204
    end

    test "returns 401 when wrong token" do
      conn =
        build_conn()
        |> post("/api/v4/jobs/request", %{token: "token-1"})

      assert conn.status == 401
    end
  end

  describe "update/4" do
    test "it updates the state of the build", %{params: params} do
      build = insert(:full_build, status: "running")
      params = Map.merge(params, %{state: "success", token: build.token, trace: "trace"})

      conn =
        build_conn()
        |> put("/api/v4/jobs/#{build.id}", params)

      {:ok, build} = Builds.get_by(build.id, build.token)

      assert conn.status == 200
      assert build.status == "success"
      assert Builds.get_trace(build) == "trace"
    end

    test "returns 403 when wrong token" do
      build = insert(:full_build, status: "running")

      conn =
        build_conn()
        |> put("/api/v4/jobs/#{build.id}", %{token: "token-1"})

      assert conn.status == 403
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
      assert Builds.get_trace(build) != ""
    end

    test "returns 403 when wrong token" do
      build = insert(:full_build, status: "running")

      raw_params =
        "\x1b[0KRunning with gitlab-ci-multi-runner 9.1.1 (6104325) on localhost.lan (OFdlS21H)
        \x1b[0;m\x1b[0KUsing Docker executor with image elixir:latest ...
        \x1b[0;m"

      conn =
        build_conn()
        |> put_req_header("job-token", "token-1")
        |> put_req_header("content-type", "text/plain")
        |> patch("/api/v4/jobs/#{build.id}/trace", raw_params)

      assert conn.status == 403
    end
  end
end
