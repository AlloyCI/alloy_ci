defmodule AlloyCi.Workers.CreateBuildsWorker do
  @moduledoc """
  """
  alias AlloyCi.{Builds, Github, Pipelines}
  require Logger

  def perform(pipeline_id) do
    pipeline = Pipelines.get_with_project(pipeline_id)
    project = pipeline.project

    token = Pipelines.installation_token(pipeline)
    client = Github.api_client(%{access_token: token["token"]})
    file = Tentacat.Contents.find_in(project.owner, project.name, ".alloy-ci.json", pipeline.sha, client)
    content = :base64.decode(file["content"])

    case Builds.create_builds_from_config(content, pipeline) do
      {:ok, _} ->
        Logger.info("Builds created successfully")
      {:error, reason} ->
        Logger.info(reason)
    end
  end
end
