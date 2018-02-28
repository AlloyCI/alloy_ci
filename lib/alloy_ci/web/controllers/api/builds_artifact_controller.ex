defmodule AlloyCi.Web.Api.BuildsArtifactController do
  use AlloyCi.Web, :controller
  alias AlloyCi.{Artifacts, Builds, Runners}

  def authorize(conn, params, _, _) do
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

  def create(conn, %{"id" => id, "file" => file, "expire_in" => expiry}, _, _) do
    [token] = get_req_header(conn, "job-token")

    with {:ok, %{artifacts: %{}} = build} <- Builds.get_by(id, token),
         {:ok, _} <- Builds.store_artifact(build, file, expiry) do
      conn
      |> put_status(201)
      |> json(%{message: "201 OK"})
    else
      {:error, nil} ->
        conn
        |> put_status(403)
        |> json(%{error: "403 Forbidden"})

      {:ok, _} ->
        conn
        |> put_status(404)
        |> json(%{error: "404 Not Found"})
    end
  end

  def show(conn, %{"id" => id}, _, _) do
    [token] = get_req_header(conn, "job-token")

    with {:ok, %{artifacts: %{}} = build} <- Builds.get_with_artifact(id, token),
         file <- Artifacts.url({build.artifact.file, build.artifact}, signed: true) do
      conn
      |> put_resp_content_type("application/octet-stream", "utf-8")
      |> put_resp_header("content-transfer-encoding", "binary")
      |> put_resp_header(
        "content-disposition",
        "attachment; filename=#{build.artifact.file[:file_name]}"
      )
      |> send_file(200, "./#{file}")
    else
      {:error, nil} ->
        conn
        |> put_status(403)
        |> json(%{error: "403 Forbidden"})

      {:ok, _} ->
        conn
        |> put_status(404)
        |> json(%{error: "404 Not Found"})
    end
  end
end
