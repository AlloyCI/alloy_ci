defmodule AlloyCi.Runners do
  @moduledoc """
  The boundary for the Runners system.
  """
  alias AlloyCi.{Builds, Project, Projects, Repo, Runner}
  import Ecto.Query, warn: false

  def all(params), do: Runner |> Repo.paginate(params)

  def can_manage?(id, user) do
    with %Runner{} = runner <- get(id),
         true <- Projects.can_manage?(runner.project_id, user) do
      {:ok, runner}
    else
      _ ->
        {:error, nil}
    end
  end

  def create(%{"token" => token, "info" => runner_info} = params) do
    if token == global_token() do
      new_runner = Enum.into(%{global: true}, runner_params(params, runner_info))
      save(new_runner)
    else
      with %Project{} = project <- Projects.get_by(token: token) do
        new_runner =
          %{global: false, project_id: project.id}
          |> Enum.into(runner_params(params, runner_info))

        save(new_runner)
      else
        _ -> nil
      end
    end
  end

  def delete_by(id: id) do
    Runner
    |> Repo.get(id)
    |> Repo.delete()
  end

  def delete_by(token: token) do
    Runner
    |> Repo.get_by(token: token)
    |> Repo.delete()
  rescue
    FunctionClauseError -> nil
  end

  def get(id), do: Runner |> Repo.get(id)

  def get_by(token: token), do: Runner |> Repo.get_by(token: token)

  def global_runners do
    Runner
    |> where([r], is_nil(r.project_id) and r.global == true)
    |> limit(10)
    |> Repo.all()
  end

  def global_token do
    Application.get_env(:alloy_ci, :runner_registration_token)
  end

  def register_job(%{project_id: nil, tags: nil} = runner) do
    Builds.to_process()
    |> Builds.start_build(runner)
  end

  def register_job(%{project_id: nil, tags: [_ | _], run_untagged: true} = runner) do
    case Builds.for_runner(runner) do
      nil ->
        Builds.to_process()
        |> Builds.start_build(runner)

      build ->
        build
        |> Builds.start_build(runner)
    end
  end

  def register_job(%{project_id: nil, tags: [_ | _]} = runner) do
    runner
    |> Builds.for_runner()
    |> Builds.start_build(runner)
  end

  def register_job(%{project_id: nil} = runner) do
    Builds.to_process()
    |> Builds.start_build(runner)
  end

  def register_job(%{project_id: project_id} = runner) do
    project_id
    |> Builds.for_project()
    |> Builds.start_build(runner)
  end

  def save(params) do
    result =
      %Runner{}
      |> Runner.changeset(params)
      |> Repo.insert()

    case result do
      {:ok, runner} -> runner
      {:error, _} -> nil
    end
  end

  def update(runner, params) do
    params =
      case params["tags"] do
        # if all tags are deleted on the frontend, params will not contain the
        # tags element, so we set it explicitly here
        nil ->
          Map.merge(params, %{"tags" => nil})

        _ ->
          params
      end

    runner
    |> Runner.changeset(params)
    |> Repo.update()
  end

  def update_info(runner, params) do
    runner
    |> Runner.changeset(params)
    |> Repo.update()
  end

  ###################
  # Private functions
  ###################
  defp runner_params(params, runner_info) do
    tags =
      case String.split(params["tag_list"] || "", ",") do
        [""] -> nil
        list -> list
      end

    %{
      active: true,
      architecture: runner_info["architecture"],
      description: params["description"],
      name: runner_info["name"],
      locked: params["locked"] || false,
      platform: runner_info["platform"],
      run_untagged: params["run_untagged"] || true,
      token: SecureRandom.urlsafe_base64(10),
      tags: tags,
      version: runner_info["version"]
    }
  end
end
