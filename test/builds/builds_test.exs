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

  describe "append_trace/2" do
    test "it appends the new trace after the old trace" do
      build = insert(:full_build, status: "running", trace: "existing trace")
      assert {:ok, _} = Builds.append_trace(build, "new trace")

      build = Builds.get(build.id)
      assert build.trace == "existing trace\nnew trace\n"
    end
  end

  describe "by_stage/1" do
    test "it returns the right grouping of builds by stage", %{pipeline: pipeline} do
      build = insert(:build, pipeline: pipeline, project: pipeline.project)
      result = Builds.by_stage(pipeline)

      assert result == [
               %{
                 "test" => [
                   %{
                     id: build.id,
                     name: build.name,
                     project_id: build.project_id,
                     status: build.status,
                     finished_at: nil,
                     started_at: nil
                   }
                 ]
               }
             ]
    end
  end

  describe "create_builds_from_config/2" do
    test "it creates elixir build with the correct data", %{pipeline: pipeline} do
      content = File.read!(".alloy-ci.json")
      {:ok, result} = Builds.create_builds_from_config(content, pipeline)

      assert result == nil

      build = Repo.one(from(b in Build, order_by: [desc: b.id], limit: 1))

      assert build.name == "mix"
      assert build.commands == ["mix test"]
      assert build.project_id == pipeline.project_id
      assert build.when == "on_success"
      assert build.tags == ["elixir", "postgres"]
    end

    test "it creates rails build with the correct data", %{pipeline: pipeline, project: project} do
      content = File.read!("test/fixtures/rails_config.json")
      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, order_by: [desc: b.id], limit: 1))

      assert build.name == "Rspec Tests"

      assert build.commands == [
               "bundle install --path vendor/bundle",
               "bundle exec rake db:setup",
               "bundle exec rspec"
             ]

      assert build.project_id == pipeline.project_id
      assert build.when == "on_success"
      assert build.tags == project.tags
      assert build.stage_idx == 1
      assert build.stage == "test"
    end

    test "it can override image settings to allow for testing against different lang versions", %{
      pipeline: pipeline
    } do
      content = File.read!("test/fixtures/full_features_config.json")
      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, order_by: [desc: b.id], limit: 1))

      assert build.name == "mix"
      assert build.commands == ["mix test"]

      assert build.options == %{
               "before_script" => [
                 "mix local.hex --force",
                 "mix local.rebar --force",
                 "mix deps.get",
                 "mix ecto.setup"
               ],
               "cache" => %{"paths" => ["_build/", "deps/"]},
               "image" => "elixir:1.5",
               "services" => ["postgres:9.6"],
               "variables" => %{
                 "DATABASE_URL" => "postgres://postgres@postgres:5432/alloy_ci_test",
                 "GITHUB_CLIENT_ID" => "fake-id",
                 "GITHUB_CLIENT_SECRET" => "fake-secret",
                 "GITHUB_APP_ID" => "1",
                 "GITHUB_SECRET_TOKEN" => "fake-token",
                 "MIX_ENV" => "test",
                 "RUNNER_REGISTRATION_TOKEN" => "lustlmc3gMl59smZ",
                 "SECRET_KEY_BASE" =>
                   "NULr4xlNDNzEwE77UHdId7cQU+vuaPJ+Q5x3l+7dppQngBsL5EkjEaMu0S9cCGbk"
               },
               "stages" => ["test", "compile", "deploy"]
             }

      assert build.project_id == pipeline.project_id
      assert build.when == "on_success"
      assert build.tags == ["elixir", "postgres"]
      assert build.stage_idx == 0
      assert build.stage == "test"
    end

    test "it can populate the artifacts section", %{pipeline: pipeline} do
      content = File.read!("test/fixtures/full_features_config.json")
      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, where: b.name == "distillery"))

      assert build.commands == ["mix docker.build --tag latest"]

      assert build.project_id == pipeline.project_id
      assert build.artifacts == %{"paths" => ["alloy_ci.tar.gz", "_build/prod/lib/alloy_ci"]}
      assert build.when == "on_success"
      assert build.tags == ["elixir", "postgres"]
      assert build.stage_idx == 1
      assert build.stage == "compile"
    end

    test "it returns error on broken data", %{pipeline: pipeline} do
      content = File.read!("test/fixtures/broken_config.json")
      {:error, result} = Builds.create_builds_from_config(content, pipeline)

      assert result == "Unable to parse JSON config file."
    end

    test "it skips the build marked `except`", %{pipeline: pipeline} do
      content = File.read!("test/fixtures/except_tag_config.json")

      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, where: b.name == ^"deploy", limit: 1))

      assert build == nil
    end

    test "it creates the build marked `except`", %{project: project} do
      pipeline = insert(:clean_pipeline, project: project, ref: "refs/tags/v1.0")
      content = File.read!("test/fixtures/except_tag_config.json")

      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, where: b.name == ^"deploy", limit: 1))

      assert build.commands == ["./deploy"]
      assert build.stage == "deploy"
    end

    test "it creates the build marked `only`", %{project: project} do
      pipeline = insert(:clean_pipeline, project: project, ref: "refs/tags/v1.0")
      content = File.read!("test/fixtures/only_tag_config.json")

      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, where: b.name == ^"deploy", limit: 1))

      assert build.commands == ["./deploy"]
      assert build.stage == "deploy"
    end

    test "it skips the build marked `only`", %{project: project} do
      pipeline = insert(:clean_pipeline, project: project, ref: "refs/heads/develop")
      content = File.read!("test/fixtures/only_tag_config.json")

      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, where: b.name == ^"deploy", limit: 1))

      assert build == nil
    end

    test "it creates the build marked `only` and `except`", %{project: project} do
      pipeline = insert(:clean_pipeline, project: project, ref: "refs/heads/issue-25")
      content = File.read!("test/fixtures/both_tags_config.json")

      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, where: b.name == ^"deploy", limit: 1))

      assert build.commands == ["./deploy"]
      assert build.stage == "deploy"
    end

    test "it skips the build marked `only` and `except`", %{project: project} do
      pipeline = insert(:clean_pipeline, project: project, ref: "AlloyCI:master")
      content = File.read!("test/fixtures/both_tags_config.json")

      {:ok, result} = Builds.create_builds_from_config(content, pipeline)
      assert result == nil

      build = Repo.one(from(b in Build, where: b.name == ^"deploy", limit: 1))

      assert build == nil
    end
  end

  describe "delete_where/1" do
    test "it deletes the correct builds", %{pipeline: pipeline} do
      build = insert(:build, pipeline: pipeline, project: pipeline.project)
      assert :ok = Builds.delete_where(project_id: pipeline.project.id)

      build = Builds.get(build.id)
      assert build == nil
    end
  end

  describe "enqueue/1" do
    test "it enqueues created build" do
      pipeline = insert(:pipeline)
      build = insert(:build, status: "created", pipeline: pipeline, project: pipeline.project)
      {:ok, result} = Builds.enqueue(build)

      assert result.status == "pending"
    end

    test "it does nothing for other builds", %{pipeline: pipeline} do
      build = insert(:build, status: "running", pipeline: pipeline, project: pipeline.project)
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
    test "it returns the oldest pending build of the current stage", %{
      pipeline: pipeline,
      project: project
    } do
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        status: "running",
        runner_id: 1,
        project_id: project.id
      )

      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        project_id: project.id,
        status: "created"
      )

      build = insert(:build, pipeline_id: pipeline.id, stage_idx: 0, project_id: project.id)
      result = Builds.for_project(project.id)

      assert result.id == build.id
    end

    test "it returns nil if no build is found", %{pipeline: pipeline, project: project} do
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        status: "running",
        runner_id: 1,
        project_id: project.id
      )

      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        status: "running",
        runner_id: 2,
        project_id: project.id
      )

      result = Builds.for_project(project.id)

      assert result == nil
    end
  end

  describe "for_runner/1" do
    test "it returns the correct build that can be run by a certain runner", %{
      pipeline: pipeline,
      project: project
    } do
      insert(:build, pipeline_id: pipeline.id, stage_idx: 1, project_id: project.id)

      build =
        insert(
          :build,
          pipeline_id: pipeline.id,
          stage_idx: 0,
          project_id: project.id,
          tags: ~w(elixir postgres)
        )

      runner = insert(:runner, tags: ~w(elixir postgres ruby))
      result = Builds.for_runner(runner)

      assert result.id == build.id
    end

    test "it returns nil if no build is found", %{pipeline: pipeline, project: project} do
      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 0,
        status: "running",
        runner_id: 1,
        project_id: project.id
      )

      insert(
        :build,
        pipeline_id: pipeline.id,
        stage_idx: 1,
        project_id: project.id,
        tags: ~w(ruby mysql)
      )

      runner = insert(:runner, tags: ~w(elixir ruby))
      result = Builds.for_runner(runner)

      assert result == nil
    end
  end

  describe "start_build/2" do
    test "updates the build status and returns the correct data" do
      project = insert(:project, secret_variables: %{"test" => "success"})
      build = insert(:full_build, project: project)
      runner = insert(:runner)

      expected_steps = [
        %{
          name: :script,
          script: ["mix deps.get", "mix test"],
          timeout: 3600,
          when: "on_success",
          allow_failure: false
        }
      ]

      {:ok, result} = Builds.start_build(build, runner)

      assert result.services == [%{name: "postgres:latest"}]
      assert result.steps == expected_steps
      assert result.status == "running"
      assert result.runner_id == runner.id
      assert %{key: "CI", public: true, value: "true"} in result.variables
      assert %{key: "test", public: false, value: "success"} in result.variables
    end

    test "updates the extended build status and returns the correct data" do
      build = insert(:extended_build)
      runner = insert(:runner)

      expected_steps = [
        %{
          name: :script,
          script: ["mix deps.get", "mix test"],
          timeout: 3600,
          when: "on_success",
          allow_failure: false
        }
      ]

      {:ok, result} = Builds.start_build(build, runner)

      assert result.services == [
               %{
                 "alias" => "post",
                 "command" => ["/bin/sh"],
                 "entrypoint" => ["/bin/sh"],
                 "name" => "postgres:latest"
               }
             ]

      assert result.steps == expected_steps
      assert result.status == "running"
      assert result.runner_id == runner.id
      assert %{key: "CI", public: true, value: "true"} in result.variables
    end

    test "it returns correct status when no build is found" do
      runner = insert(:runner)
      {:no_build, result} = Builds.start_build(nil, runner)

      assert result == nil
    end

    # TODO: Figure out how to test locks
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
    test "it returns the oldest available build to process", %{
      pipeline: pipeline,
      project: project
    } do
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
    test "it transitions the status of the build accordingly", %{
      pipeline: pipeline,
      project: project
    } do
      build = insert(:build, pipeline_id: pipeline.id, stage_idx: 1, project_id: project.id)
      result = Builds.transition_status(build)

      assert result.status == "running"
    end
  end

  describe "update_trace/2" do
    test "it overwrites the build trace" do
      build = insert(:full_build, status: "running", trace: "existing trace")
      assert {:ok, build} = Builds.update_trace(build, "new trace")

      assert build.trace == "new trace"
    end
  end
end
