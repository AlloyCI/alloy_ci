defmodule AlloyCi.Web.Api.BuildsArtifactController do
  use AlloyCi.Web, :controller
  alias AlloyCi.{Artifacts, Builds, Runners}

  def authorize(conn, params, _, _) do
    case Runners.get_by(token: params["token"]) do
      {:error, _} ->
        conn
        |> send_resp(:forbidden, "")

      {:ok, _} ->
        conn
        |> send_resp(:ok, "")
    end
  end

  def create(conn, %{"id" => id, "file" => file} = params, _, _) do
    [token] = get_req_header(conn, "job-token")

    with {:ok, %{artifacts: %{}} = build} <- Builds.get_by(id, token),
         {:ok, _} <- Builds.store_artifact(build, file, params["expire_in"]) do
      conn
      |> send_resp(:created, "")
    else
      {:error, nil} ->
        conn
        |> send_resp(:forbidden, "")

      {:ok, _} ->
        conn
        |> send_resp(:not_found, "")
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
        |> send_resp(:forbidden, "")

      {:ok, _} ->
        conn
        |> send_resp(:not_found, "")
    end
  end
end
