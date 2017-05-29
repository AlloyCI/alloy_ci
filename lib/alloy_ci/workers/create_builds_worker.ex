defmodule AlloyCi.Workers.CreateBuildsWorker do
  @moduledoc """
  """
  alias AlloyCi.{Builds, Pipelines, Workers.ProcessPipelineWorker}
  require Logger

  @github_api Application.get_env(:alloy_ci, :github_api)

  def perform(pipeline_id) do
    pipeline = Pipelines.get_with_project(pipeline_id)
    project = pipeline.project

    with %{"content" => raw_content} <- @github_api.alloy_ci_config(project, pipeline) do
      content = :base64.decode(raw_content)

      case Builds.create_builds_from_config(content, pipeline) do
        {:ok, _} ->
          Logger.info("Builds created successfully")
          @github_api.notify_pending!(project, pipeline)

          ProcessPipelineWorker.perform(pipeline_id)
        {:error, reason} ->
          Logger.info(reason)
      end
    else
      _ ->
        Logger.info(".alloy-ci.json file not found")
    end
  end
end
