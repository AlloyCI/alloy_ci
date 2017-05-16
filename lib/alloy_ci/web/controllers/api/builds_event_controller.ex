defmodule AlloyCi.Web.Api.BuildsEventController do
  use AlloyCi.Web, :controller
  alias AlloyCi.{Runner, Runners}

  def request(conn, params, _, _) do
    with %Runner{} = runner <- Runners.get_by_token(params["token"]) do
      Runners.update_info(runner, params["info"])

      case Runners.register_job(runner) do
        {:ok, build} ->
          conn
          |> put_status(201)
          |> render("build.json", build)
        {:no_build, _} ->
          conn
          |> put_req_header("x-gitlab-last-update", SecureRandom.hex())
          |> put_status(204)
          |> json(%{message: "204 No Content"})
        {:error, _} ->
          conn
          |> put_status(409)
          |> json(%{message: "409 Conflict"})
      end
    else
      nil ->
        conn
        |> put_status(401)
        |> json(%{messgae: "401 Unauthorized"})
    end
  end
end
