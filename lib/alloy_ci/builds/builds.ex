defmodule AlloyCi.Builds do
  @moduledoc """
  The boundary for the Builds system.
  """
  alias AlloyCi.{Build, ExqEnqueuer, Pipelines, Projects, Repo, Workers}
  import Ecto.Query, warn: false

  @github_api Application.get_env(:alloy_ci, :github_api)

  @global_config ~w(image cache after_script before_script stages services variables)
  @local_overrides ~w(after_script before_script cache variables)

  def append_trace(build, trace) do
    with {1, nil} <- append!(build, trace) do
      {:ok, build}
    end
  end

  def by_stage(pipeline) do
    query = from b in Build,
            where: b.pipeline_id == ^pipeline.id,
            order_by: [asc: :stage_idx],
            group_by: [b.stage, b.stage_idx],
            select: {b.stage, b.stage_idx, count(b.id)}
    stages = Repo.all(query)

    Enum.map(stages, fn {stage, stage_idx, _} ->
      query = from b in Build,
              where: b.pipeline_id == ^pipeline.id and b.stage_idx == ^stage_idx,
              order_by: [asc: :id],
              select: %{id: b.id, name: b.name, project_id: b.project_id, status: b.status}
      %{"#{stage}" => Repo.all(query)}
    end)
  end

  def cancel(pipeline) do
    query = from b in Build,
            where: b.pipeline_id == ^pipeline.id,
            update: [set: [status: "cancelled"]]
    Repo.update_all(query, [])
  end

  def create_builds_from_config(content, pipeline) do
    with {:ok, config} <- Poison.decode(content) do
      Projects.touch(pipeline.project_id)

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

  def enqueue(build) do
    if build.status == "created" do
      do_update_status(build, "pending")
    else
      build
    end
  end

  def for_pipeline_and_stage(pipeline_id, stage_idx) do
    Build
    |> where(pipeline_id: ^pipeline_id)
    |> where(stage_idx: ^stage_idx)
    |> Repo.all
  end

  def for_project(project_id) do
    pipelines = Pipelines.for_project(project_id)

    mapper = fn(p) ->
      Build
      |> where(pipeline_id: ^p.id)
      |> where([b], b.status == "pending" and is_nil(b.runner_id))
      |> order_by(asc: :inserted_at)
      |> Repo.all
    end

    pipelines
    |> Enum.map(mapper)
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
    |> List.first
  end

  def get(id) do
    Build
    |> Repo.get(id)
  end

  def get_build(id, project_id, user) do
    with true <- Projects.can_access?(project_id, user) do
      Build
      |> where(project_id: ^project_id)
      |> Repo.get(id)
    end
  end

  def get_by(id, token) do
    build =
      Build
      |> Repo.get(id)

    if build.token == token do
      {:ok, build}
    else
      {:error, nil}
    end
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
          |> Build.changeset(%{runner_id: runner.id})

        case Repo.update(changeset) do
          {:ok, build} ->
            # build was updated, prepare struct for payload delivery
            build =
              build
              |> transition_status("running")
              |> Repo.preload([:pipeline, :project])

            Pipelines.run!(build.pipeline)

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

  def to_process do
    Build
    |> where([b], b.status == "pending" and is_nil(b.runner_id))
    |> order_by(asc: :inserted_at)
    |> Repo.all
    |> List.first
  end

  def transition_status(build, status \\ nil) do
    case build.status do
      "created" -> update_status(build, status || "running")
      "pending" -> update_status(build, status || "running")
      "running" -> update_status(build, status || "success")
    end
  end

  def update_trace(build, trace) do
    build
    |> Build.changeset(%{trace: trace})
    |> Repo.update
  end

  ##################
  # Private funtions
  ##################
  defp append!(build, trace) do
    new_trace = "\n#{trace}\n"

    query = from b in Build,
            where: b.id == ^build.id,
            update: [set: [trace: fragment("? || ?", b.trace, ^new_trace)]]

    Repo.update_all(query, [])
  end

  defp after_script(build) do
    case build.options["after_script"] do
      nil -> nil
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

  defp create_build(params) do
    %Build{}
    |> Build.changeset(params)
    |> Repo.insert!
  end

  defp do_update_status(build, status) do
    build
    |> Build.changeset(%{status: status})
    |> Repo.update
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

  defp generate_token do
    SecureRandom.urlsafe_base64(10)
  end

  defp predefined_vars(build) do
    [
      %{key: "CI", value: "true", public: true},
      %{key: "ALLOY_CI", value: "true", public: true},
      %{key: "CI_SERVER_NAME", value: "AlloyCI", public: true},
      %{key: "CI_SERVER_VERSION", value: AlloyCi.Mixfile.version, public: true},
      %{key: "CI_SERVER_REVISION", value: AlloyCi.Mixfile.version, public: true},
      %{key: "CI_JOB_ID", value: Integer.to_string(build.id), public: true},
      %{key: "CI_JOB_NAME", value: build.name, public: true},
      %{key: "CI_JOB_STAGE", value: build.stage, public: true},
      %{key: "CI_JOB_TOKEN", value: build.token, public: false},
      %{key: "CI_PIPELINE_ID", value: Integer.to_string(build.project_id), public: true},
      %{key: "CI_COMMIT_SHA", value: build.pipeline.sha, public: true},
      %{key: "CI_COMMIT_REF_NAME", value: build.pipeline.ref, public: true},
      %{key: "CI_COMMIT_REF_SLUG", value: build.pipeline.ref, public: true},
      %{key: "CI_REPOSITORY_URL", value: @github_api.clone_url(build.project, build.pipeline), public: false}
    ]
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

  defp update_status(build, status) do
    case do_update_status(build, status) do
      {:ok, build} ->
        ExqEnqueuer.push(Workers.ProcessPipelineWorker, [build.pipeline_id])
        build
      {:error, _} -> nil
    end
  end
end
