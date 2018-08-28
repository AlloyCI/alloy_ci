defmodule AlloyCi.PipelinesTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Builds, Pipelines}
  import AlloyCi.Factory

  @update_attrs %{
    before_sha: "some updated before_sha",
    commit: %{"message" => "some new commit_message", "email" => "some new committer_email"},
    duration: 43,
    finished_at: ~N[2011-05-18 15:01:01.000000],
    ref: "refs/heads/master",
    sha: "some updated sha",
    started_at: ~N[2011-05-18 15:01:01.000000],
    status: "some updated status"
  }
  @invalid_attrs %{
    before_sha: nil,
    commit_message: nil,
    committer_email: nil,
    duration: nil,
    finished_at: nil,
    ref: nil,
    sha: nil,
    started_at: nil,
    status: nil
  }

  setup do
    user = insert(:user_with_project)
    [project | _] = (user |> Repo.preload(:projects)).projects
    pipeline = insert(:clean_pipeline, project: project, started_at: Timex.now())

    {:ok,
     %{
       user: user,
       project: project,
       pipeline: pipeline
     }}
  end

  describe "cancel/1" do
    test "it cancels the pipeline and its builds", %{pipeline: pipeline} do
      build = insert(:build, pipeline: pipeline, project: pipeline.project)
      assert {:ok, pipeline} = Pipelines.cancel(pipeline)
      assert pipeline.status == "cancelled"
      build = Builds.get(build.id)
      assert build.status == "cancelled"
    end
  end

  describe "create_pipeline/2" do
    test "with valid data creates a pipeline" do
      project = insert(:project)

      assert {:ok, pipeline} =
               Pipelines.create_pipeline(
                 Ecto.build_assoc(project, :pipelines),
                 params_for(:pipeline)
               )

      assert pipeline.before_sha == "00000000"
      assert pipeline.ref == "refs/heads/master"
      assert pipeline.sha == "00000000"
      assert pipeline.status == "pending"
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Pipelines.create_pipeline(%AlloyCi.Pipeline{}, @invalid_attrs)
    end
  end

  describe "delete_where/1" do
    test "it deletes the pipeline and its builds", %{pipeline: pipeline} do
      build = insert(:build, pipeline: pipeline, project: pipeline.project)
      assert :ok = Pipelines.delete_where(project_id: pipeline.project_id)

      pipeline = Pipelines.get(pipeline.id)
      assert pipeline == nil

      build = Builds.get(build.id)
      assert build == nil
    end
  end

  describe "duplicate/1" do
    test "it clones the pipeline so it can be restarted", %{pipeline: pipeline} do
      assert {:ok, clone} = Pipelines.duplicate(pipeline)
      assert clone.id != pipeline.id
      assert clone.commit == pipeline.commit
      assert clone.ref == pipeline.ref
    end
  end

  describe "failed!/1" do
    # This test still lacks a check for notifications
    test "it marks the pipeline as failed", %{pipeline: pipeline} do
      {:ok, result} = Pipelines.failed!(pipeline)

      assert result.status == "failed"
    end
  end

  describe "for_project/1" do
    test "it returns the correct pipelines", %{pipeline: pipeline, project: project} do
      [result] = Pipelines.for_project(project.id)

      assert result.id == pipeline.id
    end
  end

  describe "get_pipeline/3" do
    test "it returns the pipeline with given id", %{
      user: user,
      project: project,
      pipeline: pipeline
    } do
      p = Pipelines.get_pipeline(pipeline.id, project.id, user)
      assert p.id == pipeline.id
    end

    test "it returns nil when no pipeline", %{user: user, project: project} do
      p = Pipelines.get_pipeline(100_076, project.id, user)
      assert p == nil
    end
  end

  describe "run!/1" do
    test "when pipeline is pending", %{pipeline: pipeline} do
      assert {:ok, pipeline} = Pipelines.run!(pipeline)
      assert pipeline.status == "running"
    end

    test "when pipeline is not pending" do
      pipeline = insert(:pipeline, status: "running")
      result = Pipelines.run!(pipeline)
      assert result == nil
    end
  end

  describe "success!/1" do
    # This test still lacks a check for notifications
    test "when all builds succeeded", %{pipeline: pipeline} do
      insert(:full_build, pipeline: pipeline, project: pipeline.project, status: "success")
      insert(:full_build, pipeline: pipeline, project: pipeline.project, status: "success")
      {:ok, result} = Pipelines.success!(pipeline.id)

      assert result.status == "success"
    end

    test "when build is allowed to fail", %{pipeline: pipeline} do
      insert(:full_build, pipeline: pipeline, project: pipeline.project, status: "success")

      insert(
        :full_build,
        pipeline: pipeline,
        project: pipeline.project,
        status: "failed",
        allow_failure: true
      )

      {:ok, result} = Pipelines.success!(pipeline.id)

      assert result.status == "success"
    end
  end

  describe "update_pipeline/2" do
    test "with valid data updates the pipeline" do
      pipeline = insert(:pipeline)
      assert {:ok, pipeline} = Pipelines.update_pipeline(pipeline, @update_attrs)
      assert pipeline.before_sha == "some updated before_sha"
      assert pipeline.duration == 43
      assert pipeline.finished_at == ~N[2011-05-18 15:01:01.000000]
      assert pipeline.ref == "refs/heads/master"
      assert pipeline.sha == "some updated sha"
      assert pipeline.started_at == ~N[2011-05-18 15:01:01.000000]
      assert pipeline.status == "some updated status"
    end

    test "with invalid data returns error changeset" do
      pipeline = insert(:pipeline)
      assert {:error, %Ecto.Changeset{}} = Pipelines.update_pipeline(pipeline, @invalid_attrs)
    end
  end

  describe "update_status/2" do
    test "it marks as failed", %{pipeline: pipeline} do
      insert(:full_build, pipeline: pipeline, project: pipeline.project, status: "failed")
      {:ok, result} = Pipelines.update_status(pipeline.id)

      assert result.status == "failed"
    end

    test "it does not mark as failed", %{pipeline: pipeline} do
      insert(
        :full_build,
        pipeline: pipeline,
        project: pipeline.project,
        status: "failed",
        allow_failure: true
      )

      {:ok, result} = Pipelines.update_status(pipeline.id)

      assert result == nil
    end

    test "it marks as success", %{pipeline: pipeline} do
      insert(:full_build, pipeline: pipeline, project: pipeline.project, status: "success")
      {:ok, result} = Pipelines.update_status(pipeline.id)

      assert result.status == "success"
    end
  end
end
