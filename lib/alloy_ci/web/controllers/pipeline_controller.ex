defmodule AlloyCi.Web.PipelineController do
  use AlloyCi.Web, :controller
  alias AlloyCi.{Builds, Pipeline, Pipelines}
  plug EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access"
  plug :put_layout, "pipeline_layout.html" when action in [:show]

  def create(conn, %{"id" => id, "project_id" => project_id}, current_user, _) do
    case Pipelines.get_pipeline(id, project_id, current_user) do
      %Pipeline{} = pipeline ->
        {:ok, pipeline} = Pipelines.duplicate(pipeline)
        conn
        |> put_flash(:info, "Pipeline has been restarted successfully. Builds will be processed soon.")
        |> redirect(to: project_pipeline_path(conn, :show, project_id, pipeline))
      _ ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => id, "project_id" => project_id}, current_user, _) do
    case Pipelines.get_pipeline(id, project_id, current_user) do
      %Pipeline{} = pipeline ->
        {:ok, _} = Pipelines.cancel(pipeline)
        redirect(conn, to: project_pipeline_path(conn, :show, project_id, id))
      _ ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id, "project_id" => project_id}, current_user, _claims) do
    case Pipelines.get_pipeline(id, project_id, current_user) do
      %Pipeline{} = pipeline ->
        builds = Builds.by_stage(pipeline)
        render(conn, "show.html", builds: builds, pipeline: pipeline, current_user: current_user)
      _ ->
        conn
        |> put_flash(:info, "Project not found")
        |> redirect(to: project_path(conn, :index))
    end
  end
end
