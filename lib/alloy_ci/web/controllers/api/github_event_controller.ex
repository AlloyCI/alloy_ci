defmodule AlloyCi.Web.Api.GithubEventController do
  @moduledoc """
  """
  use AlloyCi.Web, :controller

  alias AlloyCi.{
    Accounts,
    Pipelines,
    Projects,
    Queuer,
    Workers.CreateBuildsWorker,
    Workers.ProcessPullRequestWorker
  }

  @github_api Application.get_env(:alloy_ci, :github_api)

  def handle_event(
        %{assigns: %{github_event: "push"}} = conn,
        %{"after" => "0000000000000000000000000000000000000000"},
        _,
        _
      ) do
    event = %{status: :bad_request, message: "Reference deletion is not handled"}

    render(conn, "event.json", event: event)
  end

  def handle_event(
        %{assigns: %{github_event: "push"}} = conn,
        %{"head_commit" => %{"message" => msg}} = params,
        _,
        _
      ) do
    if @github_api.skip_ci?(msg) do
      event = %{status: :ok, message: "Pipeline creation skipped"}
      render(conn, "event.json", event: event)
    else
      handle_event(conn, params)
    end
  end

  def handle_event(
        %{assigns: %{github_event: "installation"}} = conn,
        %{"action" => "created", "installation" => installation},
        _,
        _
      ) do
    params = %{
      login: installation["account"]["login"],
      target_id: installation["target_id"],
      target_type: installation["target_type"],
      uid: installation["id"]
    }

    case Accounts.create_installation(params) do
      {:ok, installation} ->
        event = %{
          status: :ok,
          message: "Installation with ID: #{installation.id} created successfully."
        }

        render(conn, "event.json", event: event)

      {:error, changeset} ->
        render(conn, "error.json", changeset: changeset)
    end
  end

  def handle_event(
        %{assigns: %{github_event: "installation"}} = conn,
        %{"action" => "deleted", "installation" => installation},
        _,
        _
      ) do
    event =
      case Accounts.delete_installation(installation["id"]) do
        {1, nil} ->
          %{
            status: :ok,
            message: "Installation with UID: #{installation["id"]} deleted successfully."
          }

        {_, _} ->
          %{status: :error, message: "Failed to delete installation."}
      end

    render(conn, "event.json", event: event)
  end

  def handle_event(
        %{assigns: %{github_event: "pull_request"}} = conn,
        %{"action" => action} = params,
        _,
        _
      )
      when action in ~w(opened synchronize) do
    Queuer.push(ProcessPullRequestWorker, params)
    event = %{status: :ok, message: "Pull request pipeline creation has been scheduled."}

    render(conn, "event.json", event: event)
  end

  def handle_event(%{assigns: %{github_event: gh_event}} = conn, _params, _, _) do
    event = %{status: :bad_request, message: "Event #{gh_event} is not handled by this endpoint."}

    render(conn, "event.json", event: event)
  end

  ###################
  # Private functions
  ###################
  defp handle_event(conn, params) do
    with %AlloyCi.Project{} = project <- Projects.get_by(repo_id: params["repository"]["id"]),
         %{"content" => _} <-
           @github_api.alloy_ci_config(project, %{
             installation_id: params["installation"]["id"],
             sha: params["head_commit"]["id"]
           }) do
      pipeline_attrs = %{
        before_sha: params["before"],
        commit: %{
          pusher_email: params["pusher"]["email"],
          username: params["sender"]["login"],
          avatar_url: params["sender"]["avatar_url"],
          message: params["head_commit"]["message"]
        },
        ref: params["ref"],
        sha: params["head_commit"]["id"],
        installation_id: params["installation"]["id"]
      }

      case Pipelines.create_pipeline(Ecto.build_assoc(project, :pipelines), pipeline_attrs) do
        {:ok, pipeline} ->
          Queuer.push(CreateBuildsWorker, pipeline.id)

          event = %{
            status: :ok,
            message: "Pipeline with ID: #{pipeline.id} created successfully."
          }

          render(conn, "event.json", event: event)

        {:error, changeset} ->
          render(conn, "error.json", changeset: changeset)
      end
    else
      nil ->
        render(conn, "event.json", event: %{status: :not_found, message: "Project not found."})

      _ ->
        render(
          conn,
          "event.json",
          event: %{status: :bad_request, message: "Config file not found for ref."}
        )
    end
  end
end
