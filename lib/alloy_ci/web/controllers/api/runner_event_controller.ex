defmodule AlloyCi.Web.Api.RunnerEventController do
  use AlloyCi.Web, :controller
  alias AlloyCi.Runners

  def register(conn, params, _, _) do
    case Runners.create(params) do
      nil ->
        conn
        |> put_status(403)
        |> json(%{message: "403 Forbidden"})
      runner ->
        conn
        |> put_status(201)
        |> json(%{id: runner.id, token: runner.token})
    end
  end

  def verify(conn, params, _, _) do
    case Runners.get_by(token: params["token"]) do
      nil ->
        conn
        |> put_status(403)
        |> json(%{message: "403 Forbidden"})
      _ ->
        conn
        |> put_status(200)
        |> json(%{message: "200 Credentials are valid"})
    end
  end

  def delete(conn, %{"token" => token}, _, _) do
    case Runners.delete_by(token: token) do
      {:ok, _} ->
        conn
        |> put_status(204)
        |> json(%{message: "204 Runner was deleted"})
      _ ->
        conn
        |> put_status(403)
        |> json(%{message: "403 Forbidden"})
    end
  end
end
