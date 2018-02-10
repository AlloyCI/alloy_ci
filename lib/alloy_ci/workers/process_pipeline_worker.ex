defmodule AlloyCi.Workers.ProcessPipelineWorker do
  @moduledoc """
  This worker takes care of processing and updating a pipeline. It is enqueued
  whenever the status of a build is updated. Its main purpose is to make sure the
  correct stage is enqueued, and that builds are enqueued based on their `when`
  constraint.
  """
  alias AlloyCi.{Builds, Pipelines, Repo}
  import Ecto.Query
  require Logger
  use Que.Worker

  def perform(pipeline_id) do
    log("Processing builds for pipeline #{pipeline_id}")

    Enum.each(build_indexes(pipeline_id), fn idx ->
      process_stage(pipeline_id, idx)
    end)

    log("Updating status for pipeline #{pipeline_id}")
    Pipelines.update_status(pipeline_id)
  end

  ###################
  # Private functions
  ###################
  defp build_indexes(pipeline_id) do
    query =
      from(
        b in "builds",
        where: b.pipeline_id == ^pipeline_id,
        order_by: :stage_idx,
        distinct: :stage_idx,
        select: b.stage_idx
      )

    Repo.all(query)
  end

  defp is_status_valid?(build_when, status) do
    case build_when do
      "on_success" -> status in ~w(success skipped)
      "on_failure" -> status == "failed"
      "always" -> true
      "manual" -> status == "success"
    end
  end

  defp process_stage(pipeline_id, stage_idx) do
    query =
      from(
        b in "builds",
        where: b.pipeline_id == ^pipeline_id and b.stage_idx < ^stage_idx,
        order_by: [desc: b.updated_at, desc: b.stage_idx],
        limit: 1,
        select: b.status
      )

    current_status = Repo.one(query) || "success"

    if current_status in ~w(success failed canceled skipped) do
      pipeline_id
      |> Builds.for_pipeline_and_stage(stage_idx)
      |> Enum.each(fn build ->
        process_build(build, current_status)
      end)
    end
  end

  defp process_build(build, status) do
    if is_status_valid?(build.when, status) do
      log("Enqueueing build #{build.id}")
      Builds.enqueue(build)
    end
  end

  defp log(value) do
    Logger.info(value)
  end
end
