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
    from(
      b in "builds",
      where: b.pipeline_id == ^pipeline_id,
      order_by: :stage_idx,
      distinct: :stage_idx,
      select: b.stage_idx
    )
    |> Repo.all()
  end

  defp log(value) do
    Logger.info(value)
  end

  defp process_build(build, status) do
    if valid_status?(build.when, status) do
      log("Enqueueing build #{build.id}")
      Builds.enqueue(build)
    end
  end

  defp process_stage(pipeline_id, stage_idx) do
    status = last_stage_status(pipeline_id, stage_idx)

    pipeline_id
    |> Builds.for_pipeline_and_stage(stage_idx)
    |> Enum.each(fn build ->
      process_build(build, status)
    end)
  end

  defp last_stage_status(pipeline_id, stage_idx) do
    stats = stage_builds_stats(pipeline_id, stage_idx)

    cond do
      stats[:total] == 0 ->
        "success"

      stats[:total] == stats[:successful] + stats[:allowed_failures] ->
        "success"

      stats[:active] > 0 ->
        "running"

      true ->
        "failed"
    end
  end

  defp stage_builds_stats(pipeline_id, stage_idx) do
    successful_builds =
      from(
        b in "builds",
        where:
          b.pipeline_id == ^pipeline_id and b.stage_idx == ^(stage_idx - 1) and
            b.status == "success",
        select: count(b.id)
      )
      |> Repo.one()

    allowed_failures =
      from(
        b in "builds",
        where:
          b.pipeline_id == ^pipeline_id and b.stage_idx == ^(stage_idx - 1) and
            b.status == "failed" and b.allow_failure == true,
        select: count(b.id)
      )
      |> Repo.one()

    active_builds =
      from(
        b in "builds",
        where:
          b.pipeline_id == ^pipeline_id and b.stage_idx == ^(stage_idx - 1) and
            b.status in ~w(pending running),
        select: count(b.id)
      )
      |> Repo.one()

    total_builds =
      from(
        b in "builds",
        where: b.pipeline_id == ^pipeline_id and b.stage_idx == ^(stage_idx - 1),
        select: count(b.id)
      )
      |> Repo.one()

    %{
      total: total_builds,
      successful: successful_builds,
      allowed_failures: allowed_failures,
      active: active_builds
    }
  end

  defp valid_status?(build_when, status) do
    case build_when do
      "on_success" -> status in ~w(success skipped)
      "on_failure" -> status == "failed"
      "always" -> true
      "manual" -> status == "success"
    end
  end
end
