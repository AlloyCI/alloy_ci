defmodule AlloyCi.Web.Api.RunnerEventControllerTest do
  @moduledoc """
  """
  alias AlloyCi.Runner
  use AlloyCi.Web.ConnCase
  import AlloyCi.Factory

  describe "register/4" do
    test "it registers a global runner" do
      params = %{
        description: "test runner",
        locked: false,
        info: %{
          architecture: "amd64",
          name: "runner",
          platform: "darwin",
          version: "9"
        },
        run_untagged: false,
        token: "lustlmc3gMl59smZ"
      }

      conn =
        build_conn()
        |> post("/api/v4/runners", params)

      runner = Repo.one(from(r in Runner, order_by: [desc: r.id], limit: 1))

      assert conn.status == 201
      assert conn.resp_body =~ "#{runner.id}"
      assert conn.resp_body =~ "#{runner.token}"
    end

    test "it registers a project runner" do
      project = insert(:project)

      params = %{
        description: "test runner",
        locked: false,
        info: %{
          architecture: "amd64",
          name: "runner",
          platform: "darwin",
          version: "9"
        },
        run_untagged: false,
        token: project.token
      }

      conn =
        build_conn()
        |> post("/api/v4/runners", params)

      runner = Repo.one(from(r in Runner, order_by: [desc: r.id], limit: 1))

      assert conn.status == 201
      assert conn.resp_body =~ "#{runner.id}"
      assert conn.resp_body =~ "#{runner.token}"
    end

    test "it returns 403 when token is invalid" do
      conn =
        build_conn()
        |> post("/api/v4/runners", %{token: "invalid", info: %{}})

      assert conn.status == 403
    end
  end

  describe "verify/4" do
    test "it responds with 200 if runner token is valid" do
      runner = insert(:runner)

      conn =
        build_conn()
        |> post("/api/v4/runners/verify", %{token: runner.token})

      assert conn.status == 200
    end

    test "it responds with 403 otherwise" do
      conn =
        build_conn()
        |> post("/api/v4/runners/verify", %{token: "invalid"})

      assert conn.status == 403
    end
  end

  describe "delete/4" do
    test "it deletes the runner if token valid" do
      runner = insert(:runner)

      conn =
        build_conn()
        |> delete("/api/v4/runners", %{token: runner.token})

      assert conn.status == 204
    end

    test "it responds with 403 otherwise" do
      conn =
        build_conn()
        |> delete("/api/v4/runners", %{token: "invalid"})

      assert conn.status == 403
    end
  end
end
