defmodule AlloyCi.Web.BuildControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  alias AlloyCi.{Artifact, Repo}
  import AlloyCi.Factory

  setup do
    project = insert(:project, private: true)
    pipeline = insert(:clean_pipeline, project: project)
    build = insert(:build, trace: "build trace", pipeline: pipeline, project: project)
    user = insert(:user)
    insert(:clean_project_permission, project: project, user: user)

    {:ok, %{project: project, build: build, user: user}}
  end

  describe "#show/4" do
    test "it responds with the chosen build", %{project: project, build: build, user: user} do
      conn =
        user
        |> guardian_login(%{typ: "access"})
        |> get("/projects/#{project.id}/builds/#{build.id}")

      assert html_response(conn, 200) =~ "#{build.trace}"
    end

    test "it redirects if user cannot access pipeline", %{project: project, build: build} do
      conn =
        :user
        |> insert()
        |> guardian_login(%{typ: "access"})
        |> get("/projects/#{project.id}/builds/#{build.id}")

      assert html_response(conn, 302) =~ "redirected"
    end
  end

  describe "#artifact/4" do
    test "it responds with the artifact file for download", %{project: project, user: user} do
      build = insert(:extended_build, status: "success", project: project)

      insert(:artifact, build: build)
      |> Artifact.changeset(%{
        file: %Plug.Upload{
          path: "test/fixtures/broken_config.json",
          filename: "broken_config.json"
        }
      })
      |> Repo.update()

      conn =
        user
        |> guardian_login(%{typ: "access"})
        |> get("/projects/#{project.id}/builds/#{build.id}/artifact")

      assert conn.status == 200
      assert conn.state == :file
      assert conn.resp_body == File.read!("test/fixtures/broken_config.json")
    end

    test "it redirects if user cannot access pipeline", %{project: project, build: build} do
      conn =
        :user
        |> insert()
        |> guardian_login(%{typ: "access"})
        |> get("/projects/#{project.id}/builds/#{build.id}/artifact")

      assert html_response(conn, 302) =~ "redirected"
    end
  end

  describe "#keep_artifact/4" do
    test "it updates the artifact expiry date", %{project: project, user: user} do
      build = insert(:extended_build, status: "success", project: project)

      artifact =
        insert(:artifact, build: build)
        |> Artifact.changeset(%{
          file: %Plug.Upload{
            path: "test/fixtures/broken_config.json",
            filename: "broken_config.json"
          },
          expires_at: Timex.now()
        })
        |> Repo.update!()

      conn =
        user
        |> guardian_login(%{typ: "access"})
        |> get("/projects/#{project.id}/builds/#{build.id}/artifact/keep")

      assert html_response(conn, 302) =~ "redirected"
      assert Repo.get!(Artifact, artifact.id).expires_at == nil
    end

    test "it redirects if user cannot access pipeline", %{project: project, build: build} do
      conn =
        :user
        |> insert()
        |> guardian_login(%{typ: "access"})
        |> get("/projects/#{project.id}/builds/#{build.id}/artifact/keep")

      assert html_response(conn, 302) =~ "redirected"
    end
  end
end
