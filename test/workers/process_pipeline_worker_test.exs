defmodule AlloyCi.ProcessPipelineWorkerTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Builds, Pipeline, Repo, Workers.ProcessPipelineWorker}
  import AlloyCi.Factory

  setup do
    project = insert(:project) |> with_user()
    pipeline = insert(:clean_pipeline, project: project, status: "running", started_at: Timex.now)
    {:ok, %{pipeline: pipeline, project: project}}
  end

  test "it processes the pipeline and updates the statuses of builds", %{pipeline: pipeline, project: project} do
    build1 = insert(:build, pipeline_id: pipeline.id, stage_idx: 0, project_id: project.id, status: "success")
    build2 = insert(:build, pipeline_id: pipeline.id, stage_idx: 1, project_id: project.id, status: "created")

    ProcessPipelineWorker.perform(pipeline.id)

    build1 = Builds.get(build1.id)
    build2 = Builds.get(build2.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert build1.status == "success"
    assert build2.status == "pending"
    assert pipeline.status == "running"

    Builds.transition_status(build2, "success")
    ProcessPipelineWorker.perform(pipeline.id)
    pipeline = Pipeline |> Repo.get(pipeline.id)

    assert pipeline.status == "success"
  end
end
