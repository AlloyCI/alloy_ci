defmodule AlloyCi.Web.Api.BuildsEventController do
  use AlloyCi.Web, :controller
  alias AlloyCi.{Builds, Runners, Web.BuildsChannel}

  def request(conn, params, _, _) do
    with {:ok, runner} <- Runners.get_by(token: params["token"]) do
      Runners.update_info(runner, params["info"])

      case Runners.register_job(runner) do
        {:ok, build} ->
          conn
          |> put_status(201)
          |> render("build.json", build |> Map.from_struct())

        {:no_build, _} ->
          conn
          |> put_req_header("x-gitlab-last-update", SecureRandom.hex())
          |> send_resp(:no_content, "")

        {:error, _} ->
          conn
          |> send_resp(:conflict, "")
      end
    else
      {:error, _} ->
        conn
        |> send_resp(:unauthorized, "")
    end
  end

  def trace(conn, %{"id" => id}, _, _) do
    [token] = get_req_header(conn, "job-token")
    {:ok, trace, conn} = read_body(conn)

    with {:ok, build} <- Builds.get_by(id, token),
         {:ok, build} <- Builds.append_trace(build, trace) do
      BuildsChannel.send_trace(build.id, trace)

      conn
      |> put_status(202)
      |> put_resp_header("job-status", build.status)
      |> put_resp_header("range", "0-100")
      |> json(%{message: "202 Trace was patched"})
    else
      {:error, _} ->
        conn
        |> send_resp(:forbidden, "")
    end
  end

  def update(conn, %{"id" => id, "token" => token} = params, _, _) do
    case Builds.get_by(id, token) do
      {:error, _} ->
        conn
        |> send_resp(:forbidden, "")

      {:ok, build} ->
        case params["state"] do
          "failed" -> Builds.transition_status(build, "failed")
          "success" -> Builds.transition_status(build, "success")
          "running" -> Builds.transition_status(build, "running")
        end

        case params["trace"] do
          nil ->
            :ok

          _ ->
            Builds.update_trace(build, params["trace"])
            BuildsChannel.replace_trace(build.id, params["trace"])
        end

        conn
        |> send_resp(:ok, "")
    end
  end
end
