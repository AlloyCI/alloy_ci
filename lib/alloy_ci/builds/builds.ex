defmodule AlloyCi.Builds do
  @moduledoc """
  The boundary for the Builds system.
  """
  alias AlloyCi.{
    Artifact,
    Build,
    BuildsTraceCache,
    Pipeline,
    Pipelines,
    Projects,
    Queuer,
    Repo,
    Runner,
    User,
    Web.BuildsChannel,
    Workers
  }

  import Ecto.Query, warn: false

  @github_api Application.get_env(:alloy_ci, :github_api)

  @global_config ~w(after_script before_script cache image services stages variables)
  @local_overrides ~w(after_script before_script cache image services variables)

  @spec append_trace(Build.t(), binary()) :: {:ok, Build.t()}
  def append_trace(build, ""), do: {:ok, build}

  def append_trace(build, trace) do
    old_trace = BuildsTraceCache.lookup(build.id)
    new_trace = old_trace <> "\n#{trace}"

    with :ok <- BuildsTraceCache.insert(build.id, new_trace) do
      {:ok, build}
    end
  end

  @spec by_stage(Pipeline.t()) :: [map()]
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
            status: b.status,
            when: b.when
          }
        )

      %{stage => Repo.all(query)}
    end)
  end

  @spec clean_ref(binary()) :: binary()
  def clean_ref(ref) do
    String.replace(ref, ref |> ref_type() |> cleanup_string(), "")
  end

  @spec create_builds_from_config(binary(), any()) :: {:error, <<_::264>>} | {:ok, nil}
  def create_builds_from_config(content, pipeline) do
    with {:ok, config} <- YamlElixir.read_from_string(content) do
      Projects.touch(pipeline.project_id)

      global_options = Map.take(config, @global_config)
      stages = config["stages"] || ["build", "test", "deploy"]
      build_jobs = Map.drop(config, @global_config)

      Enum.each(build_jobs, fn job ->
        create_build_from_map(job, global_options, stages, pipeline)
      end)

      {:ok, nil}
    else
      {:error, _} ->
        {:error, "Unable to parse YAML config file."}
    end
  end

  @spec create_build_from_map({binary(), map()}, map(), list(), any()) :: nil | Build.t()
  def create_build_from_map({"." <> _, _}, _, _, _), do: nil

  def create_build_from_map({name, options}, global_options, stages, pipeline) do
    local_options = Map.merge(global_options, Map.take(options, @local_overrides))
    stage = options["stage"] || "test"

    build_params = %{
      allow_failure: options["allow_failure"] || default_allow_failure(options["when"]),
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
  end

  @spec delete_where([{:project_id, pos_integer()}, ...]) :: :error | :ok
  def delete_where(project_id: id) do
    query =
      Build
      |> where(project_id: ^id)

    case Repo.delete_all(query) do
      {_, nil} -> :ok
      _ -> :error
    end
  end

  @spec enqueue(Build.t()) :: Build.t()
  def enqueue(%{status: "created", when: "manual"} = build) do
    do_update_status(build, "manual")
  end

  def enqueue(%{status: status, when: when_at} = build)
      when status in ~w(created manual) and when_at !== "manual" do
    do_update_status(build, "pending")
  end

  def enqueue(build), do: build

  @spec enqueue!(Build.t()) :: Build.t()
  def enqueue!(build), do: do_update_status(build, "pending")

  @spec for_pipeline_and_lower_stage(pos_integer(), pos_integer()) :: [Build.t()]
  def for_pipeline_and_lower_stage(pipeline_id, stage_idx) do
    Build
    |> where(pipeline_id: ^pipeline_id)
    |> where([b], b.stage_idx < ^stage_idx)
    |> order_by(asc: :stage_idx, asc: :updated_at)
    |> preload(:artifact)
    |> Repo.all()
  end

  @spec for_pipeline_and_stage(pos_integer(), pos_integer()) :: [Build.t()]
  def for_pipeline_and_stage(pipeline_id, stage_idx) do
    Build
    |> where(pipeline_id: ^pipeline_id)
    |> where(stage_idx: ^stage_idx)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @spec for_project(pos_integer()) :: Build.t()
  def for_project(project_id) do
    Build
    |> where(project_id: ^project_id)
    |> where([b], b.status == "pending" and is_nil(b.runner_id))
    |> order_by(asc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @spec for_runner(Runner.t()) :: Build.t()
  def for_runner(runner) do
    # Select a build whose tags are fully contained in the runner's tags
    Build
    |> where([b], b.status == "pending" and is_nil(b.runner_id))
    |> where([b], fragment("? <@ ?", b.tags, ^runner.tags))
    |> order_by(asc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @spec get(binary() | pos_integer()) :: Build.t()
  def get(id), do: Build |> Repo.get(id)

  @spec get_build(pos_integer(), pos_integer(), User.t()) :: false | nil | Build.t()
  def get_build(id, project_id, user) do
    with true <- Projects.can_access?(project_id, user) do
      Build
      |> where(project_id: ^project_id)
      |> preload([:artifact, :project, :pipeline])
      |> Repo.get(id)
    end
  end

  @spec get_by(pos_integer(), binary()) :: {:error, nil} | {:ok, Build.t()}
  def get_by(id, token) do
    build = get(id)

    if build.token == token do
      {:ok, build}
    else
      {:error, nil}
    end
  end

  @spec get_with_artifact(any(), any()) :: {:error, nil} | {:ok, Build.t()}
  def get_with_artifact(id, token) do
    with {:ok, build} <- get_by(id, token) do
      {:ok, build |> Repo.preload(:artifact)}
    end
  end

  @spec get_trace(Build.t()) :: binary()
  def get_trace(%{id: id, status: "running"}), do: BuildsTraceCache.lookup(id)
  def get_trace(build), do: build.trace

  @spec keep_artifact(Build.t()) :: {:error, any()} | {:ok, Build.t()}
  def keep_artifact(build) do
    build.artifact
    |> Artifact.changeset(%{expires_at: nil})
    |> Repo.update()
  end

  @spec ref_type(binary()) :: binary()
  def ref_type(ref) do
    ref_types = [{~r/heads/, "branches"}, {~r/tags/, "tags"}, {~r/:/, "forks"}]

    {_, type} =
      Enum.find(ref_types, {nil, ""}, fn {expr, _} ->
        Regex.match?(expr, ref)
      end)

    type
  end

  @spec retry(Build.t()) :: {:ok, Build.t()} | {:error, any()}
  def retry(build) do
    with {:ok, _} <-
           build |> do_update(%{allow_failure: true, name: build.name <> " (restarted)"}) do
      params =
        build
        |> Map.drop([
          :__meta__,
          :__struct__,
          :id,
          :inserted_at,
          :updated_at,
          :finished_at,
          :queued_at,
          :started_at,
          :runner_id,
          :status,
          :trace,
          :token
        ])
        |> Map.merge(%{token: generate_token(), status: "pending"})

      %Build{}
      |> Build.changeset(params)
      |> Repo.insert()
    end
  end

  @spec start_build(nil | Build.t(), Runner.t()) ::
          {:error, any()} | {:no_build, nil} | {:ok, map()}
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

  @spec store_artifact(Build.t(), any(), binary()) :: any()
  def store_artifact(build, file, expire_in) when is_nil(expire_in) or expire_in == "",
    do: do_store_artifact(build, file, "7d")

  def store_artifact(build, file, expire_in), do: do_store_artifact(build, file, expire_in)

  @spec to_process() :: Build.t()
  def to_process do
    Build
    |> where([b], b.status == "pending" and is_nil(b.runner_id) and is_nil(b.tags))
    |> order_by(asc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @spec transition_status(Build.t(), binary() | nil) :: Build.t()
  def transition_status(build, status \\ nil) do
    case build.status do
      s when s in ~w(created pending) -> update_status(build, status || "running")
      s when s in ~w(manual running) -> update_status(build, status || "success")
      _ -> build
    end
  end

  @spec update_trace(Build.t(), binary()) :: {:ok, Build.t()} | {:error, any()}
  def update_trace(build, trace) do
    BuildsTraceCache.delete(build.id)

    build
    |> do_update(%{trace: trace})
  end

  ###################
  # Private functions
  ###################
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

  defp cleanup_string("branches"), do: "refs/heads/"
  defp cleanup_string("tags"), do: "refs/tags/"
  defp cleanup_string(_), do: "refs/"

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

  defp default_allow_failure("manual"), do: true
  defp default_allow_failure(_when), do: false

  defp do_create_build(params) do
    %Build{}
    |> Build.changeset(params)
    |> Repo.insert!()
  end

  defp do_store_artifact(build, file, expire_in) do
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

  defp do_update(build, params) do
    build
    |> Build.changeset(params)
    |> Repo.update()
  end

  defp do_update_status(build, status) when status in ~w(success failed) do
    build
    |> do_update(%{status: status, finished_at: Timex.now()})
  end

  defp do_update_status(build, status) when status == "pending" do
    build
    |> do_update(%{status: status, queued_at: Timex.now()})
  end

  defp do_update_status(build, status) when status == "running" do
    build
    |> do_update(%{status: status, started_at: Timex.now()})
  end

  defp do_update_status(build, status) do
    build
    |> do_update(%{status: status})
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
      %{key: "CI_COMMIT_MESSAGE", value: build.pipeline.commit["message"], public: true},
      %{key: "CI_COMMIT_PUSHER", value: build.pipeline.commit["pusher_email"], public: true},
      %{key: "CI_COMMIT_REF_NAME", value: build.pipeline.ref, public: true},
      %{key: "CI_COMMIT_REF_SLUG", value: clean_ref(build.pipeline.ref), public: true},
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
        BuildsChannel.update_status(build)
        build

      {:error, _} ->
        nil
    end
  end
end
