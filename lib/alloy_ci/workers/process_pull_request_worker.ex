defmodule AlloyCi.Workers.ProcessPullRequestWorker do
  @moduledoc """
  When a pull request is created, and it is coming from a fork, this worker
  processes the information from the PR and the forked repo to create a special
  pipeline to test the code from the fork. Requires a custom version of the Runner
  until https://gitlab.com/gitlab-org/gitlab-runner/merge_requests/765 is merged. 
  """
  alias AlloyCi.{Pipelines, Projects, Workers.CreateBuildsWorker, Queuer}
  require Logger
  use Que.Worker

  @github_api Application.get_env(:alloy_ci, :github_api)

  def perform(
        %{
          "pull_request" => %{"head" => %{"repo" => %{"fork" => true}}, "base" => base},
          "number" => pull_id
        } = params
      ) do
    with %AlloyCi.Project{} = project <- Projects.get_by(repo_id: base["repo"]["id"]),
         pull_request <- @github_api.pull_request(project, pull_id, params["installation"]["id"]),
         %{"commit" => %{"message" => message}} <-
           @github_api.commit(project, pull_request["head"]["sha"], params["installation"]["id"]),
         %{"content" => _} <-
           @github_api.alloy_ci_config(project, %{
             installation_id: params["installation"]["id"],
             sha: pull_request["head"]["sha"]
           }) do
      pipeline_attrs = %{
        before_sha: pull_request["base"]["sha"],
        commit: %{
          username: params["sender"]["login"],
          avatar_url: params["sender"]["avatar_url"],
          message: "PR ##{pull_id}: #{pull_request["title"]}",
          pr_commit_message: message
        },
        ref: pull_request["head"]["label"],
        sha: pull_request["head"]["sha"],
        installation_id: params["installation"]["id"]
      }

      case Pipelines.create_pipeline(Ecto.build_assoc(project, :pipelines), pipeline_attrs) do
        {:ok, pipeline} ->
          Queuer.push(CreateBuildsWorker, pipeline.id)
          Logger.info("Pipeline with ID: #{pipeline.id} created successfully.")

        {:error, _} ->
          Logger.info("Unable to create pipeline.")
      end
    else
      nil ->
        Logger.info("Project not found when attempting to create pipeline for fork.")

      _ ->
        Logger.info(
          "Unable to find necessary params (config file or commit message) for pipeline creation."
        )
    end
  end

  def perform(%{"pull_request" => pull_request}) do
    Logger.info("Pull request with ID: #{pull_request["id"]} is not from a fork.")
  end
end
