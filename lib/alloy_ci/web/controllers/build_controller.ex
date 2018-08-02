defmodule AlloyCi.Web.BuildController do
  use AlloyCi.Web, :controller
  alias AlloyCi.{Artifacts, Build, Builds}
  plug(EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access")

  def artifact(conn, %{"build_id" => id, "project_id" => project_id}, current_user, _) do
    case Builds.get_build(id, project_id, current_user) do
      false ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))

      build ->
        file = Artifacts.url({build.artifact.file, build.artifact}, signed: true)

        if System.get_env("S3_STORAGE_ENABLED") do
          conn |> redirect(external: file)
        else
          conn
          |> put_resp_content_type("application/octet-stream", "utf-8")
          |> put_resp_header("content-transfer-encoding", "binary")
          |> put_resp_header(
            "content-disposition",
            "attachment; filename=#{build.artifact.file[:file_name]}"
          )
          |> send_file(200, "./#{file}")
        end
    end
  end

  def create(conn, %{"id" => id, "project_id" => project_id}, current_user, _) do
    with %Build{} = build <- Builds.get_build(id, project_id, current_user),
         {:ok, build} <- Builds.retry(build) do
      conn
      |> put_flash(:success, "Build has been restarted")
      |> redirect(to: project_pipeline_path(conn, :show, project_id, build.pipeline_id))
    else
      false ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def keep_artifact(conn, %{"build_id" => id, "project_id" => project_id}, current_user, _) do
    with %Build{} = build <- Builds.get_build(id, project_id, current_user),
         {:ok, _} <- Builds.keep_artifact(build) do
      conn
      |> put_flash(:success, "Artifact will be kept forever")
      |> redirect(to: project_build_path(conn, :show, project_id, build))
    else
      false ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id, "project_id" => project_id}, current_user, _) do
    case Builds.get_build(id, project_id, current_user) do
      false ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))

      build ->
        conn
        |> render("show.html", build: build, pipeline: build.pipeline, current_user: current_user)
    end
  end

  def update(conn, %{"id" => id, "project_id" => project_id}, current_user, _) do
    case Builds.get_build(id, project_id, current_user) do
      false ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))

      build ->
        with {:ok, _} <- Builds.enqueue!(build) do
          conn
          |> put_flash(:success, "Build successfully started")
          |> redirect(to: project_build_path(conn, :show, build.project_id, build))
        else
          _ ->
            conn
            |> put_flash(:error, "An error occurred starting the build")
            |> redirect(to: project_pipeline_path(conn, :show, project_id, build.pipeline_id))
        end
    end
  end
end
