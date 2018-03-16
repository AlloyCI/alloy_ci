defmodule AlloyCi.Builds do
  @moduledoc """
  The boundary for the Builds system.
  """
  alias AlloyCi.{Artifact, Build, Queuer, Pipelines, Projects, Repo, Workers}
  import Ecto.Query, warn: false

  @github_api Application.get_env(:alloy_ci, :github_api)

  @global_config ~w(after_script before_script cache image services stages variables)
  @local_overrides ~w(after_script before_script cache image services variables)

  def append_trace(build, trace) do
    with {1, nil} <- append!(build, trace) do
      {:ok, build}
    end
  end

  def by_stage(pipeline) do
    query =
      from(
        b in Build,
        where: b.pipeline_id == ^pipeline.id,
        order_by: [asc: :stage_idx],
        group_by: [b.stage, b.stage_idx],
        select: {b.stage, b.stage_idx, count(b.id)}
      )

    stages = Repo.all(query)

    Enum.map(stages, fn {stage, stage_idx, _} ->
      query =
        from(
          b in Build,
          where: b.pipeline_id == ^pipeline.id and b.stage_idx == ^stage_idx,
          order_by: [asc: :id],
          select: %{
            id: b.id,
            finished_at: b.finished_at,
            name: b.name,
            project_id: b.project_id,
            started_at: b.started_at,
            status: b.status
          }
        )

      %{stage => Repo.all(query)}
    end)
  end

  def cancel(pipeline) do
    query =
      from(
        b in Build,
        where: b.pipeline_id == ^pipeline.id,
        update: [set: [status: "cancelled"]]
      )

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
        stage = options["stage"] || "test"

        build_params = %{
          allow_failure: options["allow_failure"] || false,
          artifacts: options["artifacts"],
          commands: options["script"],
          deps: options["dependencies"],
          name: name,
          options: local_options,
          stage: stage,
          stage_idx: Enum.find_index(stages, &(&1 == stage)),
          tags: options["tags"] || pipeline.project.tags,
          token: generate_token(),
          variables: local_options["variables"],
          pipeline_id: pipeline.id,
          project_id: pipeline.project_id,
          when: options["when"] || "on_success"
        }

        creation_options = %{
          except: options["except"],
          ref: pipeline.ref,
          only: options["only"]
        }

        create_build(build_params, creation_options)
      end)

      {:ok, nil}
    else
      {:error, _} ->
        {:error, "Unable to parse JSON config file."}
    end
  end

  def delete_where(project_id: id) do
    query =
      Build
      |> where(project_id: ^id)

    case Repo.delete_all(query) do
      {_, nil} -> :ok
      _ -> :error
    end
  end

  def enqueue(build) do
    if build.status == "created" do
      do_update_status(build, "pending")
    else
      build
    end
  end

  def for_pipeline_and_lower_stage(pipeline_id, stage_idx) do
    Build
    |> where(pipeline_id: ^pipeline_id)
    |> where([b], b.stage_idx < ^stage_idx)
    |> order_by(asc: :stage_idx, asc: :updated_at)
    |> preload(:artifact)
    |> Repo.all()
  end

  def for_pipeline_and_stage(pipeline_id, stage_idx) do
    Build
    |> where(pipeline_id: ^pipeline_id)
    |> where(stage_idx: ^stage_idx)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  def for_project(project_id) do
    Build
    |> where(project_id: ^project_id)
    |> where([b], b.status == "pending" and is_nil(b.runner_id))
    |> order_by(asc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def for_runner(runner) do
    # Select builds whose tags are fully contained in the runner's tags
    Build
    |> where([b], b.status == "pending" and is_nil(b.runner_id))
    |> where([b], fragment("? <@ ?", b.tags, ^runner.tags))
    |> order_by(asc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get(id), do: Build |> Repo.get(id)

  def get_build(id, project_id, user) do
    with true <- Projects.can_access?(project_id, user) do
      Build
      |> where(project_id: ^project_id)
      |> preload([:artifact, :project, :pipeline])
      |> Repo.get(id)
    end
  end

  def get_by(id, token) do
    build = get(id)

    if build.token == token do
      {:ok, build}
    else
      {:error, nil}
    end
  end

  def get_with_artifact(id, token) do
    with {:ok, build} <- get_by(id, token) do
      {:ok, build |> Repo.preload(:artifact)}
    end
  end

  def keep_artifact(build) do
    build.artifact
    |> Artifact.changeset(%{expires_at: nil})
    |> Repo.update()
  end

  def ref_type(ref) do
    ref_types = [{~r/heads/, "branches"}, {~r/tags/, "tags"}, {~r/:/, "forks"}]

    {_, type} =
      Enum.find(ref_types, {nil, ""}, fn {expr, _} ->
        Regex.match?(expr, ref)
      end)

    type
  end

  def retry(build) do
    build
    |> Build.changeset(%{runner_id: nil, status: "pending", trace: ""})
    |> Repo.update()
  end

  def start_build(build, runner) do
    with %Build{} <- build do
      # start build and check conflict
      Repo.transaction(fn ->
        changeset =
          Build
          |> where(id: ^build.id)
          |> lock("FOR UPDATE")
          |> Repo.one()
          |> Build.changeset(%{runner_id: runner.id})

        case Repo.update(changeset) do
          {:ok, build} ->
            # build was updated, prepare struct for payload delivery
            build =
              build
              |> transition_status("running")
              |> Repo.preload([:artifact, :pipeline, :project, :runner])

            Pipelines.run!(build.pipeline)

            Map.merge(build, extra_fields(build))

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    else
      nil -> {:no_build, nil}
    end
  end

  def store_artifact(build, file, expire_in) do
    expires_at = Timex.now() |> Timex.shift(seconds: expire_in |> TimeConvert.to_seconds())
    build = build |> Repo.preload(:artifact)

    case build.artifact do
      nil ->
        Repo.transaction(fn ->
          with {:ok, artifact} <-
                 %Artifact{}
                 |> Artifact.changeset(%{build_id: build.id, expires_at: expires_at})
                 |> Repo.insert(),
               {:ok, artifact} <- artifact |> Artifact.changeset(%{file: file}) |> Repo.update() do
            {:ok, artifact}
          else
            {:error, changeset} ->
              Repo.rollback(changeset)
              {:error, changeset}
          end
        end)

      artifact ->
        artifact |> Artifact.changeset(%{file: file}) |> Repo.update()
    end
  end

  def to_process do
    Build
    |> where([b], b.status == "pending" and is_nil(b.runner_id) and is_nil(b.tags))
    |> order_by(asc: :inserted_at)
    |> limit(1)
    |> Repo.one()
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
    |> Repo.update()
  end

  ###################
  # Private functions
  ###################
  defp append!(_build, ""), do: {1, nil}

  defp append!(build, trace) do
    new_trace = "\n#{trace}\n"

    query =
      from(
        b in Build,
        where: b.id == ^build.id,
        update: [set: [trace: fragment("? || ?", b.trace, ^new_trace)]]
      )

    Repo.update_all(query, [])
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

  defp build_dependencies(%{deps: [_ | _]} = build) do
    build.deps
    |> Enum.map(&named_dependencies(&1, build))
    |> Enum.reject(&is_nil/1)
  end

  defp build_dependencies(build) do
    with true <- Pipelines.has_artifacts?(build.pipeline) do
      build.pipeline_id
      |> for_pipeline_and_lower_stage(build.stage_idx)
      |> Enum.map(&map_dependency/1)
      |> Enum.reject(&is_nil/1)
    else
      _ ->
        []
    end
  end

  defp create_build(params, %{only: nil, except: nil}), do: do_create_build(params)

  defp create_build(params, %{except: nil} = options) do
    if should_build(options[:only], options[:ref]) do
      do_create_build(params)
    end
  end

  defp create_build(params, %{only: nil} = options) do
    if !should_build(options[:except], options[:ref]) do
      do_create_build(params)
    end
  end

  defp create_build(params, options) do
    if should_build(options[:only], options[:ref]) &&
         !should_build(options[:except], options[:ref]) do
      do_create_build(params)
    end
  end

  defp do_create_build(params) do
    %Build{}
    |> Build.changeset(params)
    |> Repo.insert!()
  end

  defp do_update_status(build, status) when status in ~w(success failed) do
    build
    |> Build.changeset(%{status: status, finished_at: Timex.now()})
    |> Repo.update()
  end

  defp do_update_status(build, status) when status == "pending" do
    build
    |> Build.changeset(%{status: status, queued_at: Timex.now()})
    |> Repo.update()
  end

  defp do_update_status(build, status) when status == "running" do
    build
    |> Build.changeset(%{status: status, started_at: Timex.now()})
    |> Repo.update()
  end

  defp do_update_status(build, status) do
    build
    |> Build.changeset(%{status: status})
    |> Repo.update()
  end

  defp extra_fields(build) do
    variables =
      Enum.map(build.variables || [], fn {key, value} ->
        %{key: key, value: value, public: true}
      end)

    services = Enum.map(build.options["services"] || [], &map_service/1)

    %{
      image: map_service(build.options["image"]),
      dependencies: build_dependencies(build),
      services: services,
      steps: steps(build),
      variables: predefined_vars(build) ++ variables ++ project_variables(build)
    }
  end

  defp generate_token, do: SecureRandom.urlsafe_base64(10)

  defp map_dependency(%{artifacts: %{}} = build) do
    %{
      id: build.id,
      name: build.name,
      token: build.token,
      artifacts_file: %{filename: build.artifact.file[:file_name], size: 2500}
    }
  end

  defp map_dependency(_), do: nil

  defp map_service(%{} = service) do
    service
  end

  defp map_service(service) do
    %{name: service}
  end

  defp named_dependencies(name, build) do
    Build
    |> where(
      [b],
      b.pipeline_id == ^build.pipeline_id and b.stage_idx < ^build.stage_idx and b.name == ^name
    )
    |> preload(:artifact)
    |> Repo.one()
    |> map_dependency()
  end

  defp predefined_vars(build) do
    [
      %{key: "ALLOY_CI", value: "true", public: true},
      %{key: "CI", value: "true", public: true},
      %{key: "CI_COMMIT_REF_NAME", value: build.pipeline.ref, public: true},
      %{key: "CI_COMMIT_REF_SLUG", value: build.pipeline.ref, public: true},
      %{key: "CI_COMMIT_SHA", value: build.pipeline.sha, public: true},
      %{key: "CI_JOB_ID", value: Integer.to_string(build.id), public: true},
      %{key: "CI_JOB_NAME", value: build.name, public: true},
      %{key: "CI_JOB_STAGE", value: build.stage, public: true},
      %{key: "CI_JOB_TOKEN", value: build.token, public: false},
      %{key: "CI_PIPELINE_ID", value: Integer.to_string(build.pipeline_id), public: true},
      %{key: "CI_PROJECT_NAME", value: build.project.name, public: true},
      %{key: "CI_PROJECT_NAMESPACE", value: build.project.owner, public: true},
      %{
        key: "CI_PROJECT_PATH",
        value: "#{build.project.owner}/#{build.project.name}",
        public: true
      },
      %{
        key: "CI_REPOSITORY_URL",
        value: @github_api.clone_url(build.project, build.pipeline),
        public: false
      },
      %{key: "CI_RUNNER_ID", value: Integer.to_string(build.runner_id), public: true},
      %{key: "CI_RUNNER_TAGS", value: runner_tags(build.runner), public: true},
      %{key: "CI_SERVER_NAME", value: "AlloyCI", public: true},
      %{key: "CI_SERVER_VERSION", value: AlloyCi.Version.version(), public: true},
      # We need to set this key, because the GitLab CI Runner is a bit stupid in
      # this regard. It fetches the SSL certificate of the coordinator and tries
      # to match it against the Git server. In GitLab's case they are one and the
      # same, but here one is the AlloyCI server, and the other is GitHub.com.
      # This means that if AlloyCI uses SSL, the Runner will try to match this
      # certificate chain to GitHub's chain, resulting in an SSL error every time.
      %{key: "GIT_SSL_NO_VERIFY", value: "true", public: true}
    ]
  end

  defp project_variables(build) do
    Enum.map(build.project.secret_variables || [], fn {key, value} ->
      %{key: key, value: value, public: false}
    end)
  end

  defp runner_tags(runner) do
    if runner.tags do
      runner.tags |> Enum.join(",")
    end
  end

  defp should_build(conditions, ref) do
    Enum.reduce_while(conditions, false, fn condition, _acc ->
      with {:ok, regex} <- Regex.compile(condition) do
        cond do
          # begin checking for matching condition & type, e.g. "branches", or "forks"
          condition == ref_type(ref) ->
            {:halt, true}

          # if that fails, try to match with the created regex, will work for branch/tag
          # names and regex, e.g. "master" or "issue-.*$"
          Regex.match?(regex, ref) ->
            {:halt, true}

          # if that fails, try to match the regex again, this time against the proper
          # reference name, e.g. for refs/tags/v1.0.0 it's v1.0.0. Useful for regex
          # like "\\Av[0-9]+\\.[0-9]+\\.[0-9]+\\Z"
          Regex.match?(regex, ref |> String.split("/") |> List.last()) ->
            {:halt, true}

          # if that fails, there is no match, continue with the next condition
          true ->
            {:cont, false}
        end
      else
        _ ->
          {:cont, false}
      end
    end)
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
    |> Enum.reject(&is_nil/1)
  end

  defp update_status(build, status) do
    case do_update_status(build, status) do
      {:ok, build} ->
        Queuer.push(Workers.ProcessPipelineWorker, build.pipeline_id)
        build

      {:error, _} ->
        nil
    end
  end
end
