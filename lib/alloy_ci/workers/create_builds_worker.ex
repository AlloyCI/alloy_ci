defmodule AlloyCi.Workers.CreateBuildsWorker do
  @moduledoc """
  """
  alias AlloyCi.{Builds, Github, Pipelines}
  require Logger

  def perform(pipeline_id) do
    pipeline = Pipelines.get_with_project(pipeline_id)
    project = pipeline.project


    with %{"content" => raw_content} <- Github.alloy_ci_config(project, pipeline) do
      content = :base64.decode(raw_content)

      case Builds.create_builds_from_config(content, pipeline) do
        {:ok, _} ->
          Logger.info("Builds created successfully")
        {:error, reason} ->
          Logger.info(reason)
      end
    else
      _ ->
        Logger.info(".alloy-ci.json file not found")
    end
  end
end
