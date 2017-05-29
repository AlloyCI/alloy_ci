defmodule AlloyCi.BuildsTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Build, Builds, Repo}
  import AlloyCi.Factory

  setup do
    project = insert(:project)
    pipeline = insert(:clean_pipeline, project: project)

    {:ok, %{project: project, pipeline: pipeline}}
  end

  describe "create_builds_from_config/2" do
    test "it creates build with the correct data", %{pipeline: pipeline} do
      content = File.read!(".alloy-ci.json")

      {:ok, result} = Builds.create_builds_from_config(content, pipeline)

      assert result == nil

      build = Repo.one(from b in Build, order_by: [desc: b.id], limit: 1)

      assert build.name == "mix"
      assert build.commands == ["mix test"]
      assert build.project_id == pipeline.project_id
      assert build.when == "on_success"
      assert build.tags == ["elixir", "postgres"]
    end

    test "it returns error on broken data", %{pipeline: pipeline} do
      content = File.read!("test/fixtures/broken_config.json")

      {:error, result} = Builds.create_builds_from_config(content, pipeline)

      assert result == "Unable to parse JSON config file."
    end
  end

  describe "enqueue/1" do
    test "it enqueues created build" do
      build = insert(:full_build, status: "created")
      {:ok, result} = Builds.enqueue(build)

      assert result.status == "pending"
    end

    test "it does nothing for other builds" do
      build = insert(:full_build, status: "running")
      result = Builds.enqueue(build)

      assert result.status == "running"
    end
  end

  describe "for_pipeline_and_stage/2" do
    test "returns the correct build", %{pipeline: pipeline, project: project} do
      insert(:build, pipeline_id: pipeline.id, stage_idx: 0, project_id: project.id)
      build = insert(:build, pipeline_id: pipeline.id, stage_idx: 0, project_id: project.id)

      result = Builds.for_pipeline_and_stage(pipeline.id, 0)

      assert Enum.count(result) == 2
      assert build in result
    end
  end

  describe "for_project/1" do
    test "it returns the oldest pending build of the current stage", %{pipeline: pipeline, project: project} do
      insert(:build, pipeline_id: pipeline.id, stage_idx: 0, status: "running", runner_id: 1, project_id: project.id)
      insert(:build, pipeline_id: pipeline.id, stage_idx: 1, project_id: project.id, status: "created")

      build = insert(:build, pipeline_id: pipeline.id, stage_idx: 0, project_id: project.id)
      result = Builds.for_project(project.id)

      assert result.id == build.id
    end

    test "it returns nil if no build is found", %{pipeline: pipeline, project: project} do
      insert(:build, pipeline_id: pipeline.id, stage_idx: 0, status: "running", runner_id: 1, project_id: project.id)
      insert(:build, pipeline_id: pipeline.id, stage_idx: 1, status: "running", runner_id: 2, project_id: project.id)

      result = Builds.for_project(project.id)

      assert result == nil
    end
  end

  describe "for_runner/1" do
    test "it returns the correct build that can be run by a certain runner", %{pipeline: pipeline, project: project} do
      insert(:build, pipeline_id: pipeline.id, stage_idx: 1, project_id: project.id)

      build = insert(:build, pipeline_id: pipeline.id, stage_idx: 0, project_id: project.id, tags: ["elixir"])
      runner = insert(:runner, tags: ["elixir", "ruby"])
      result = Builds.for_runner(runner)

      assert result.id == build.id
    end

    test "it returns nil if no build is found", %{pipeline: pipeline, project: project} do
      insert(:build, pipeline_id: pipeline.id, stage_idx: 0, status: "running", runner_id: 1, project_id: project.id)
      insert(:build, pipeline_id: pipeline.id, stage_idx: 1, project_id: project.id)

      runner = insert(:runner, tags: ["elixir", "ruby"])
      result = Builds.for_runner(runner)

      assert result == nil
    end
  end

  describe "start_build/2" do
    test "updates the build status and returns the correct data" do
      build = insert(:full_build)
      runner = insert(:runner)

      expected_steps = [
        %{name: :script, script: ["mix deps.get", "mix test"],
          timeout: 3600, when: "on_success", allow_failure: false}
      ]

      {:ok, result} = Builds.start_build(build, runner)

      assert result.services == [%{name: "postgres:latest"}]
      assert result.steps == expected_steps
      assert result.status == "running"
      assert result.runner_id == runner.id
    end

    test "it returns correct status when no build is found" do
      runner = insert(:runner)
      {:no_build, result} = Builds.start_build(nil, runner)

      assert result == nil
    end

    # test "it can handle conflicts" do
    #   build = insert(:full_build)
    #   runner = insert(:runner)
    #
    #   Repo.transaction(fn ->
    #     lock =
    #       Build
    #       |> where(id: ^build.id)
    #       |> lock("FOR UPDATE")
    #       |> Repo.one
    #
    #     {:error, result} = Builds.start_build(build, runner)
    #
    #     assert result.valid? == false
    #   end)
    # end
  end

  describe "to_process" do
    test "it returns the oldest available build to process", %{pipeline: pipeline, project: project} do
      build = insert(:build, pipeline_id: pipeline.id, stage_idx: 1, project_id: project.id)
      phoenix = insert(:project)
      ph_pipeline = insert(:clean_pipeline, project: phoenix)
      insert(:build, pipeline_id: ph_pipeline.id, stage_idx: 1, project_id: phoenix.id)

      result = Builds.to_process()

      assert result.id == build.id
    end

    test "it returns nil if no build is found" do
      result = Builds.to_process()

      assert result == nil
    end
  end

  describe "transition_status/2" do
    test "it transitions the status of the build accordingly", %{pipeline: pipeline, project: project} do
      build = insert(:build, pipeline_id: pipeline.id, stage_idx: 1, project_id: project.id)
      result = Builds.transition_status(build)

      assert result.status == "running"
    end
  end
end
