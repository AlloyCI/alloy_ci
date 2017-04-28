defmodule AlloyCi.Workers.CreateBuildsWorker do
  @moduledoc """
  """
  alias AlloyCi.{Builds, Pipelines}
  require Logger

  def perform(pipeline_id) do
    pipeline = Pipelines.get_with_project(pipeline_id)
    project = pipeline.project

    token = Pipelines.installation_token(pipeline)
    client = Tentacat.Client.new(%{access_token: token})
    config = Tentacat.Contents.find_in(project.owner, project.name, ".alloy-ci.json", pipeline.sha, client)

    case Builds.create_builds_from_config(config, pipeline) do
      {:ok, _} ->
        Logger.info("Builds created successfully")
      {:error, reason} ->
        Logger.info(reason)
    end
  end
end
