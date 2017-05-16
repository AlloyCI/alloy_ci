defmodule AlloyCi.Pipelines do
  @moduledoc """
  The boundary for the Pipelines system.
  """

  import Ecto.Query, warn: false
  alias AlloyCi.{Pipeline, Projects, Repo}

  @doc """
  Returns the list of pipelines.

  ## Examples

      iex> list_pipelines()
      [%Pipeline{}, ...]

  """
  def list_pipelines(project_id, user) do
    with {:ok, project} <- Projects.get_by(project_id, user) do
      project = Repo.preload(project, :pipelines)
      {:ok, project.pipelines}
    end
  end

  def for_project(project_id) do
    Pipeline
    |> where(project_id: ^project_id)
    |> where([p], p.status == "pending" or p.status == "running")
    |> order_by(asc: :inserted_at)
    |> Repo.all
  end

  def to_process do
    Pipeline
    |> where([p], p.status == "pending" or p.status == "running")
    |> order_by(asc: :inserted_at)
    |> Repo.all
  end

  @doc """
  Gets a single pipeline.

  Raises `Ecto.NoResultsError` if the Pipeline does not exist.

  ## Examples

      iex> get_pipeline!(123)
      %Pipeline{}

      iex> get_pipeline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pipeline!(id, project_id, user) do
    with {:ok, _} <- Projects.get_by(project_id, user) do
      Pipeline
      |> where(project_id: ^project_id)
      |> Repo.get!(id)
      |> Repo.preload([:builds, :project])
    end
  end

  def get_with_project(id) do
    Pipeline
    |> Repo.get_by(id: id)
    |> Repo.preload(:project)
  end

  @doc """
  Creates a pipeline.

  ## Examples

      iex> create_pipeline(%{field: value})
      {:ok, %Pipeline{}}

      iex> create_pipeline(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pipeline(params \\ %{}) do
    %Pipeline{}
    |> Pipeline.changeset(params)
    |> Repo.insert()
  end

  def create_pipeline(pipeline, params) do
    pipeline
    |> Pipeline.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Updates a pipeline.

  ## Examples

      iex> update_pipeline(pipeline, %{field: new_value})
      {:ok, %Pipeline{}}

      iex> update_pipeline(pipeline, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pipeline(%Pipeline{} = pipeline, params) do
    pipeline
    |> Pipeline.changeset(params)
    |> Repo.update()
  end

  def current_stage_for(pipeline_id) do
    query = from b in "builds",
            where: b.pipeline_id == ^pipeline_id and b.status == "pending" and is_nil(b.runner_id),
            order_by: [asc: b.stage_idx], limit: 1,
            select: b.stage_idx

    Repo.one(query)
  end
end
