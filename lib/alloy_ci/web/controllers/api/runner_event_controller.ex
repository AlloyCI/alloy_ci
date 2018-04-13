defmodule AlloyCi.Web.Api.RunnerEventController do
  use AlloyCi.Web, :controller
  alias AlloyCi.Runners

  def register(conn, params, _, _) do
    case Runners.create(params) do
      nil ->
        conn
        |> send_resp(:forbidden, "")

      runner ->
        conn
        |> put_status(201)
        |> json(%{id: runner.id, token: runner.token})
    end
  end

  def verify(conn, params, _, _) do
    case Runners.get_by(token: params["token"]) do
      {:error, _} ->
        conn
        |> send_resp(:forbidden, "")

      {:ok, _} ->
        conn
        |> send_resp(:ok, "")
    end
  end

  def delete(conn, %{"token" => token}, _, _) do
    case Runners.delete_by(token: token) do
      {:ok, _} ->
        conn
        |> send_resp(:no_content, "")

      _ ->
        conn
        |> send_resp(:forbidden, "")
    end
  end
end
