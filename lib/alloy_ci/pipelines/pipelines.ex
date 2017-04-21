defmodule AlloyCi.Pipelines do
  @moduledoc """
  The boundary for the Pipelines system.
  """

  import Ecto.{Query, Changeset}, warn: false
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
      |> Repo.preload(:builds)
    end
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
end
