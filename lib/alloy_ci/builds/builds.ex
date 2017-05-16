defmodule AlloyCi.Builds do
  @moduledoc """
  The boundary for the Builds system.
  """
  alias AlloyCi.{Build, Github, Pipelines, Repo}
  import Ecto.Query, warn: false

  @global_config ~w(image cache after_script before_script stages services variables)
  @local_overrides ~w(after_script before_script variables)

  def create_builds_from_config(content, pipeline) do
    with {:ok, config} <- Poison.decode(content) do
      global_options = Map.take(config, @global_config)
      stages = config["stages"] || ["build", "test", "deploy"]

      build_jobs = Map.drop(config, @global_config)

      Enum.each(build_jobs, fn {name, options} ->
        local_options = Map.merge(global_options, Map.take(options, @local_overrides))
        build_params = %{
          allow_failure: options["allow_failure"] || false,
          commands: options["script"],
          name: name,
          options: local_options,
          stage: options["stage"] || "test",
          stage_idx: Enum.find_index(stages, &(&1 == options["stage"])),
          tags: options["tags"] || pipeline.project.tags,
          token: generate_token(),
          variables: local_options["variables"],
          pipeline_id: pipeline.id,
          project_id: pipeline.project_id,
          when: options["when"] || "on_success"
        }

        create_build(build_params)
      end)

      {:ok, nil}
    else
      {:error, _} ->
        {:error, "Unable to parse JSON config file."}
    end
  end

  def for_project(project_id) do
    pipelines = Pipelines.for_project(project_id)

    Enum.map(pipelines, fn(p) ->
      current_stage = Pipelines.current_stage_for(p.id)

      Build
      |> where(pipeline_id: ^p.id)
      |> where(stage_idx: ^current_stage)
      |> where([b], b.status == "pending" and is_nil(b.runner_id))
      |> order_by(asc: :inserted_at)
      |> Repo.all
    end)
    |> List.flatten
    |> List.first
  end

  def for_runner(runner) do
    Build
    |> where([b], b.status == "pending" and is_nil(b.runner_id))
    # Select builds that have a subset of the tags this runner has
    |> where([b], fragment("? && ?", b.tags, ^runner.tags))
    |> order_by(asc: :inserted_at)
    |> Repo.all
    |> Enum.filter(fn(b) ->
      current_stage = Pipelines.current_stage_for(b.pipeline_id)
      b.stage_idx == current_stage
    end)
    |> List.first
  end

  def to_process do
    Build
    |> where([b], b.status == "pending" and is_nil(b.runner_id))
    |> order_by(asc: :inserted_at)
    |> Repo.all
    |> Enum.filter(fn(b) ->
      current_stage = Pipelines.current_stage_for(b.pipeline_id)
      b.stage_idx == current_stage
    end)
    |> List.first
  end

  def start_build(build, runner) do
    with %Build{} <- build do
      # start build and check conflict
      Repo.transaction(fn ->
        changeset =
          Build
          |> where(id: ^build.id)
          |> lock("FOR UPDATE")
          |> Repo.one
          |> Build.changeset(%{runner_id: runner.id, status: "running"})

        case Repo.update(changeset) do
          {:ok, build} ->
            # build was updated, prepare struct for payload delivery
            build = build |> Repo.preload([:pipeline, :project])

            Map.merge(build, extra_fields(build))
          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    else
      nil ->
        {:no_build, nil}
    end
  end

  defp create_build(params) do
    %Build{}
    |> Build.changeset(params)
    |> Repo.insert!()
  end

  defp generate_token do
    SecureRandom.urlsafe_base64(10)
  end

  defp extra_fields(build) do
    variables = Enum.map(build.variables || [], fn {key, value} ->
      %{key: key, value: value, public: true}
    end)

    services = Enum.map(build.options["services"] || [], &(%{name: &1}))

    %{
      variables: predefined_vars(build) ++ variables,
      steps: steps(build),
      services: services
    }
  end

  defp steps(build) do
    [
      %{
        name: :script,
        script: (build.options["before_script"] || []) ++ build.commands,
        timeout: 3600,
        when: build.when,
        allow_failure: build.allow_failure
      },
      after_script(build)
    ]
    |> Enum.reject(&(&1 == nil))
  end

  defp after_script(build) do
    case build.options["after_script"] do
      nil ->
        nil
      _ ->
        %{
          name: :after_script,
          script: build.options["after_script"],
          timeout: 3600,
          when: "always",
          allow_failure: true
        }
    end
  end

  defp predefined_vars(build) do
    [
      %{key: "CI", value: true, public: true},
      %{key: "GITLAB_CI", value: true, public: true},
      %{key: "CI_SERVER_NAME", value: "AlloyCI", public: true},
      %{key: "CI_SERVER_VERSION", value: AlloyCi.Mixfile.version, public: true},
      %{key: "CI_SERVER_REVISION", value: AlloyCi.Mixfile.version, public: true},
      %{key: "CI_JOB_ID", value: build.id, public: true},
      %{key: "CI_JOB_NAME", value: build.name, public: true},
      %{key: "CI_JOB_STAGE", value: build.stage, public: true},
      %{key: "CI_JOB_TOKEN", value: build.token, public: false},
      %{key: "CI_COMMIT_SHA", value: build.pipeline.sha, public: true},
      %{key: "CI_COMMIT_REF_NAME", value: build.pipeline.ref, public: true},
      %{key: "CI_COMMIT_REF_SLUG", value: build.pipeline.ref, public: true},
      %{key: "CI_REPOSITORY_URL", value: Github.clone_url(build.project, build.pipeline), public: false}
    ]
  end
end
