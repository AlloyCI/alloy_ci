defmodule AlloyCi.Web.Api.GithubEventController do
  @moduledoc """
  """
  use AlloyCi.Web, :controller
  alias AlloyCi.{ExqEnqueuer, Pipelines, Projects, Workers.CreateBuildsWorker}

  @github_api Application.get_env(:alloy_ci, :github_api)

  def handle_event(%{assigns: %{github_event: "push"}} = conn, %{"after" => "0000000000000000000000000000000000000000"}, _, _) do
    event = %{status: :bad_request, message: "Branch deletion is not handled"}

    render(conn, "event.json", event: event)
  end

  def handle_event(%{assigns: %{github_event: "push"}} = conn, %{"head_commit" => %{"message" => msg}} = params, _, _) do
    if @github_api.skip_ci?(msg) do
      event = %{status: :ok, message: "Pipeline creation skipped"}
      render(conn, "event.json", event: event)
    else
      handle_event(conn, params)
    end
  end

  def handle_event(%{assigns: %{github_event: gh_event}} = conn, _params, _, _) do
    event = %{status: :bad_request, message: "Event #{gh_event} is not handled by this endpoint."}

    render(conn, "event.json", event: event)
  end

  ##################
  # Private funtions
  ##################
  defp handle_event(conn, params) do
    with %AlloyCi.Project{} = project <- Projects.get_by(repo_id: params["repository"]["id"]),
         %{"content" => _} <- @github_api.alloy_ci_config(project, %{installation_id: params["installation"]["id"], sha: params["after"]})
    do
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

      case Pipelines.create_pipeline(Ecto.build_assoc(project, :pipelines), pipeline_attrs) do
        {:ok, pipeline} ->
          ExqEnqueuer.push(CreateBuildsWorker, [pipeline.id])
          event = %{status: :ok, message: "Pipeline with ID: #{pipeline.id} created sucessfully."}
          render(conn, "event.json", event: event)
        {:error, changeset} ->
          render(conn, "error.json", changeset: changeset)
      end
    else
      nil ->
        render(conn, "event.json", event: %{status: :not_found, message: "Project not found."})
      _ ->
        render(conn, "event.json", event: %{status: :bad_request, message: "Config file not found for ref."})
    end
  end
end
