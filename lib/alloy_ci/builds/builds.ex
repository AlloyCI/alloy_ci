defmodule AlloyCi.Builds do
  @moduledoc """
  The boundary for the Builds system.
  """
  alias AlloyCi.{Build, Repo}

  @global_config ~w(image cache after_script before_script stages services variables)
  @local_overrides ~w(after_script before_script variables)

  def create_builds_from_config(content, pipeline) do
    with {:ok, config} <- Poison.decode(content) do
      global_options = Map.take(config, @global_config)
      stages = config["stages"] || ["build", "test", "deploy"]

      build_jobs = Map.drop(config, @global_config ++ @variables)

      Enum.each(build_jobs, fn {name, options} ->
        local_options = Map.merge(global_options, Map.take(options, @local_overrides))
        build_params = %{
          allow_failure: options["allow_failure"] || false,
          commands: options["script"],
          name: name,
          options: local_options,
          stage: options["stage"] || "test",
          stage_idx: Enum.find_index(stages, &(&1 == options["stage"])),
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

  def create_build(params \\ %{}) do
    %Build{}
    |> Build.changeset(params)
    |> Repo.insert()
  end

  def generate_token do
    SecureRandom.base64(12)
  end
end
