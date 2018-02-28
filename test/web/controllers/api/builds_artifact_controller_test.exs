defmodule AlloyCi.Web.Api.BuildsArtifactControllerTest do
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

  describe "create/4" do
    test "it creates a new artifact" do
      build = insert(:extended_build, status: "running")

      params = %{
        file: %Plug.Upload{
          path: "test/fixtures/broken_config.json",
          filename: "broken_config.json"
        },
        expire_in: "7d"
      }

      conn =
        build_conn()
        |> put_req_header("job-token", build.token)
        |> post("/api/v4/jobs/#{build.id}/artifacts", params)

      {:ok, build} = Builds.get_with_artifact(build.id, build.token)

      assert conn.status == 201
      assert build.artifact != nil
      assert build.artifact.file[:file_name] == "broken_config.json"
    end

    test "returns 403 when wrong token" do
      build = insert(:extended_build, status: "running")

      conn =
        build_conn()
        |> put_req_header("job-token", "token-1")
        |> post("/api/v4/jobs/#{build.id}/artifacts", %{file: "", expire_in: ""})

      assert conn.status == 403
      assert conn.resp_body =~ "Forbidden"
    end

    test "returns 404 when build does not declare artifacts" do
      build = insert(:full_build, status: "running")

      conn =
        build_conn()
        |> put_req_header("job-token", build.token)
        |> post("/api/v4/jobs/#{build.id}/artifacts", %{file: "", expire_in: ""})

      assert conn.status == 404
      assert conn.resp_body =~ "Not Found"
    end
  end

  describe "show/4" do
    test "it downloads the correct artifact" do
      build = insert(:extended_build, status: "success")

      insert(:artifact, build: build)
      |> Artifact.changeset(%{
        file: %Plug.Upload{
          path: "test/fixtures/broken_config.json",
          filename: "broken_config.json"
        }
      })
      |> Repo.update()

      conn =
        build_conn()
        |> put_req_header("job-token", build.token)
        |> get("/api/v4/jobs/#{build.id}/artifacts")

      assert conn.status == 200
      assert conn.state == :file
      assert conn.resp_body == File.read!("test/fixtures/broken_config.json")
    end

    test "returns 403 when wrong token" do
      build = insert(:extended_build, status: "running")

      conn =
        build_conn()
        |> put_req_header("job-token", "token-1")
        |> get("/api/v4/jobs/#{build.id}/artifacts")

      assert conn.status == 403
      assert conn.resp_body =~ "Forbidden"
    end

    test "returns 404 when build does not declare artifacts" do
      build = insert(:full_build, status: "running")

      conn =
        build_conn()
        |> put_req_header("job-token", build.token)
        |> get("/api/v4/jobs/#{build.id}/artifacts")

      assert conn.status == 404
      assert conn.resp_body =~ "Not Found"
    end
  end
end
