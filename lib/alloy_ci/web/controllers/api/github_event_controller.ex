defmodule AlloyCi.Web.Api.GithubEventController do
  @moduledoc """
  """
  use AlloyCi.Web, :controller

  alias AlloyCi.{Pipelines, Projects, Workers.CreateBuildsWorker}

  def handle_event(%{assigns: %{github_event: "push"}} = conn, params, _, _) do
    with %AlloyCi.Project{} = project <- Projects.get_by_repo_id(params["repository"]["id"]) do
      pipeline_attrs = %{
        before_sha: params["before"],
        commit: %{
          username: params["sender"]["login"],
          avatar_url: params["sender"]["avatar_url"],
          message: params["head_commit"]["message"]
        },
        ref: params["ref"],
        sha: params["after"],
        installation_id: params["installation"]["id"]
      }

      pipeline = Ecto.build_assoc(project, :pipelines)

      case Pipelines.create_pipeline(pipeline, pipeline_attrs) do
        {:ok, pipeline} ->
          Exq.enqueue(Exq, "default", CreateBuildsWorker, [pipeline.id])
          event = %{status: :ok, message: "Pipeline with ID: #{pipeline.id} created sucessfully."}
          render(conn, "event.json", event: event)
        {:error, changeset} ->
          render(conn, "error.json", changeset: changeset)
      end
    else
      nil ->
        render(conn, "event.json", event: %{status: :not_found, message: "Project not found."})
    end
  end

  def handle_event(%{assigns: %{github_event: gh_event}} = conn, _params, _, _) do
    event = %{status: :bad_request, message: "Event #{gh_event} is not handled by this endpoint."}

    render(conn, "event.json", event: event)
  end
end
