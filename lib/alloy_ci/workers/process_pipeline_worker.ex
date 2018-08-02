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

      stats[:total] ==
          stats[:successful] + stats[:allowed_failures] + stats[:non_blocking_manual_builds] ->
        "success"

      stats[:active] > 0 || stats[:blocking_manual_builds] > 0 ->
        "running"

      true ->
        "failed"
    end
  end

  defp stage_builds_stats(pipeline_id, stage_idx) do
    active_builds =
      from(
        b in "builds",
        where:
          b.pipeline_id == ^pipeline_id and b.stage_idx == ^(stage_idx - 1) and
            b.status in ~w(pending running),
        select: count(b.id)
      )
      |> Repo.one()

    successful_builds =
      from(
        b in "builds",
        where:
          b.pipeline_id == ^pipeline_id and b.stage_idx == ^(stage_idx - 1) and
            b.status == "success",
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
      active: active_builds,
      successful: successful_builds,
      total: total_builds,
      allowed_failures:
        status_counter(pipeline_id, stage_idx, %{status: "failed", allowed_failure: true}),
      non_blocking_manual_builds:
        status_counter(pipeline_id, stage_idx, %{status: "manual", allowed_failure: true}),
      blocking_manual_builds:
        status_counter(pipeline_id, stage_idx, %{status: "manual", allowed_failure: false})
    }
  end

  defp status_counter(pipeline_id, stage_idx, opts) do
    from(
      b in "builds",
      where:
        b.pipeline_id == ^pipeline_id and b.stage_idx == ^(stage_idx - 1) and
          b.status == ^opts.status and b.allow_failure == ^opts.allowed_failure,
      select: count(b.id)
    )
    |> Repo.one()
  end

  defp valid_status?(build_when, last_stage_status) do
    case build_when do
      "on_success" -> last_stage_status in ~w(success skipped)
      "on_failure" -> last_stage_status == "failed"
      "always" -> true
      "manual" -> last_stage_status == "success"
    end
  end
end
