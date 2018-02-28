defmodule AlloyCi.ProcessPipelineWorkerTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Builds, Pipeline, Repo, Workers.ProcessPipelineWorker}
  import AlloyCi.Factory

  setup do
    project = insert(:project) |> with_user()

    pipeline =
      insert(:clean_pipeline, project: project, status: "running", started_at: Timex.now())

    {:ok, %{pipeline: pipeline, project: project}}
  end

  test "it processes the pipeline and updates the statuses of builds", %{
    pipeline: pipeline,
    project: project
  } do
    build1 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        project_id: project.id,
        status: "success"
      )

    build2 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        project_id: project.id,
        status: "created"
      )

    ProcessPipelineWorker.perform(pipeline.id)

    build1 = Builds.get(build1.id)
    build2 = Builds.get(build2.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert build1.status == "success"
    assert build2.status == "pending"
    assert build2.queued_at != nil
    assert pipeline.status == "running"

    Builds.transition_status(build2, "success")
    ProcessPipelineWorker.perform(pipeline.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert pipeline.status == "success"
  end

  test "it processes the pipeline and updates the builds on failure", %{
    pipeline: pipeline,
    project: project
  } do
    insert(
      :build,
      pipeline_id: pipeline.id,
      stage_idx: 0,
      project_id: project.id,
      status: "success"
    )

    build2 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        project_id: project.id,
        status: "failed"
      )

    build3 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        project_id: project.id,
        status: "created",
        when: "on_failure"
      )

    ProcessPipelineWorker.perform(pipeline.id)

    build2 = Builds.get(build2.id)
    build3 = Builds.get(build3.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert build2.status == "failed"
    assert build3.status == "pending"
    assert pipeline.status == "running"

    build3 = Builds.transition_status(build3, "success")
    assert build3.finished_at != nil
    ProcessPipelineWorker.perform(pipeline.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert pipeline.status == "failed"
  end

  test "it processes the pipeline and updates the second stage on success", %{
    pipeline: pipeline,
    project: project
  } do
    insert(
      :build,
      pipeline_id: pipeline.id,
      stage_idx: 0,
      project_id: project.id,
      status: "success"
    )

    build2 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        project_id: project.id,
        status: "success"
      )

    build3 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        project_id: project.id,
        status: "created"
      )

    ProcessPipelineWorker.perform(pipeline.id)

    build2 = Builds.get(build2.id)
    build3 = Builds.get(build3.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert build2.status == "success"
    assert build3.status == "pending"
    assert pipeline.status == "running"

    Builds.transition_status(build3, "success")
    ProcessPipelineWorker.perform(pipeline.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert pipeline.status == "success"
  end

  test "it doesn't processes the pipeline and updates the second stage on failure", %{
    pipeline: pipeline,
    project: project
  } do
    insert(
      :build,
      pipeline_id: pipeline.id,
      stage_idx: 0,
      project_id: project.id,
      status: "success"
    )

    build2 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        project_id: project.id,
        status: "failed"
      )

    build3 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        project_id: project.id,
        status: "created"
      )

    ProcessPipelineWorker.perform(pipeline.id)

    build2 = Builds.get(build2.id)
    build3 = Builds.get(build3.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert build2.status == "failed"
    assert build3.status == "created"
    assert pipeline.status == "failed"

    Builds.transition_status(build3, "success")
    ProcessPipelineWorker.perform(pipeline.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert pipeline.status == "failed"
  end

  test "it processes the pipeline and updates the second stage on success or allowed failures", %{
    pipeline: pipeline,
    project: project
  } do
    insert(
      :build,
      pipeline_id: pipeline.id,
      stage_idx: 0,
      project_id: project.id,
      status: "success"
    )

    build2 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        project_id: project.id,
        status: "failed",
        allow_failure: true
      )

    build3 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        project_id: project.id,
        status: "created"
      )

    ProcessPipelineWorker.perform(pipeline.id)

    build2 = Builds.get(build2.id)
    build3 = Builds.get(build3.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert build2.status == "failed"
    assert build3.status == "pending"
    assert pipeline.status == "running"

    Builds.transition_status(build3, "success")
    ProcessPipelineWorker.perform(pipeline.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert pipeline.status == "success"
  end

  test "it processes the pipeline and updates the builds on success", %{
    pipeline: pipeline,
    project: project
  } do
    build1 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        project_id: project.id,
        status: "success"
      )

    build2 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        project_id: project.id,
        status: "created",
        when: "on_failure"
      )

    build3 =
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        project_id: project.id
      )

    ProcessPipelineWorker.perform(pipeline.id)

    build1 = Builds.get(build1.id)
    build2 = Builds.get(build2.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert build1.status == "success"
    assert build2.status == "created"
    assert pipeline.status == "running"

    Builds.transition_status(build3, "success")
    ProcessPipelineWorker.perform(pipeline.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert pipeline.status == "success"
  end
end
