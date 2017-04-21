defmodule AlloyCi.PipelinesTest do
  @moduledoc """
  """
  use AlloyCi.DataCase

  alias AlloyCi.Pipelines
  alias AlloyCi.Pipeline
  import AlloyCi.Factory

  @update_attrs %{before_sha: "some updated before_sha", commit: %{message: "some new commit_message", email: "some new committer_email"}, duration: 43, finished_at: ~N[2011-05-18 15:01:01.000000], ref: "some updated ref", sha: "some updated sha", started_at: ~N[2011-05-18 15:01:01.000000], status: "some updated status"}
  @invalid_attrs %{before_sha: nil, commit_message: nil, committer_email: nil, duration: nil, finished_at: nil, ref: nil, sha: nil, started_at: nil, status: nil}

  setup do
    user = insert(:user_with_project)
    [project | _] = (user |> Repo.preload(:projects)).projects
    pipeline = insert(:pipeline, project: project)
    {:ok, %{
        user: user,
        project: project,
        pipeline: pipeline
      }
    }
  end

  test "list_pipelines/2 returns all pipelines", %{user: user, project: project, pipeline: pipeline} do
    {:ok, [p]} = Pipelines.list_pipelines(project.id, user)
    assert p.id == pipeline.id
  end

  test "get_pipeline! returns the pipeline with given id", %{user: user, project: project, pipeline: pipeline} do
    p = Pipelines.get_pipeline!(pipeline.id, project.id, user)
    assert p.id == pipeline.id
  end

  test "create_pipeline/1 with valid data creates a pipeline" do
    project = insert(:project)
    assert {:ok, %Pipeline{} = pipeline} = Pipelines.create_pipeline(params_for(:pipeline, project_id: project.id))
    assert pipeline.before_sha == "00000000"
    assert pipeline.ref == "master"
    assert pipeline.sha == "00000000"
    assert pipeline.status == "pending"
  end

  test "create_pipeline/1 with invalid data returns error changeset" do
    assert {:error, %Ecto.Changeset{}} = Pipelines.create_pipeline(@invalid_attrs)
  end

  test "update_pipeline/2 with valid data updates the pipeline" do
    pipeline = insert(:pipeline)
    assert {:ok, pipeline} = Pipelines.update_pipeline(pipeline, @update_attrs)
    assert %Pipeline{} = pipeline
    assert pipeline.before_sha == "some updated before_sha"
    assert pipeline.duration == 43
    assert pipeline.finished_at == ~N[2011-05-18 15:01:01.000000]
    assert pipeline.ref == "some updated ref"
    assert pipeline.sha == "some updated sha"
    assert pipeline.started_at == ~N[2011-05-18 15:01:01.000000]
    assert pipeline.status == "some updated status"
  end

  test "update_pipeline/2 with invalid data returns error changeset" do
    pipeline = insert(:pipeline)
    assert {:error, %Ecto.Changeset{}} = Pipelines.update_pipeline(pipeline, @invalid_attrs)
  end
end
