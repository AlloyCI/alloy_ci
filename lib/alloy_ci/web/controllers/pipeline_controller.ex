defmodule AlloyCi.Web.PipelineController do
  use AlloyCi.Web, :controller
  alias AlloyCi.{Builds, Pipeline, Pipelines}

  plug(EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access")
  plug(:put_layout, "pipeline_layout.html" when action in [:show])

  def create(conn, %{"id" => id, "project_id" => project_id}, current_user, _) do
    with %Pipeline{} = pipeline <- Pipelines.get_pipeline(id, project_id, current_user),
         {:ok, pipeline} <- Pipelines.duplicate(pipeline) do
      conn
      |> put_flash(
        :info,
        "Pipeline has been restarted successfully. Builds will be processed soon."
      )
      |> redirect(to: project_pipeline_path(conn, :show, project_id, pipeline))
    else
      _ ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => id, "project_id" => project_id}, current_user, _) do
    with %Pipeline{} = pipeline <- Pipelines.get_pipeline(id, project_id, current_user),
         {:ok, _} <- Pipelines.cancel(pipeline) do
      conn
      |> put_flash(:info, "Pipeline has been cancelled")
      |> redirect(to: project_pipeline_path(conn, :show, project_id, id))
    else
      _ ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id, "project_id" => project_id}, current_user, _claims) do
    with %Pipeline{} = pipeline <- Pipelines.for_project_and_user(id, project_id, current_user) do
      builds = Builds.by_stage(pipeline)
      render(conn, "show.html", builds: builds, pipeline: pipeline, current_user: current_user)
    else
      _ ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end
end
