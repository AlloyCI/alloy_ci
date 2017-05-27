defmodule AlloyCi.Pipelines do
  @moduledoc """
  The boundary for the Pipelines system.
  """
  import Ecto.Query, warn: false
  alias AlloyCi.{Github, Pipeline, Projects, Repo}

  def create_pipeline(pipeline, params) do
    pipeline
    |> Pipeline.changeset(params)
    |> Repo.insert()
  end

  def failed!(pipeline) do
    pipeline = pipeline |> Repo.preload(:project)
    Github.notify_failure!(pipeline.project, pipeline)
    {:ok, _} = update_pipeline(pipeline, %{status: "failed"})
    # Notify user that pipeline failed. (Email and badge)
  end

  def for_project(project_id) do
    Pipeline
    |> where(project_id: ^project_id)
    |> where([p], p.status == "pending" or p.status == "running")
    |> order_by(asc: :inserted_at)
    |> Repo.all
  end

  def get(id) do
    Pipeline
    |> Repo.get_by(id: id)
  end

  def get_pipeline(id, project_id, user) do
    with true <- Projects.can_access?(project_id, user) do
      Pipeline
      |> where(project_id: ^project_id)
      |> Repo.get(id)
      |> Repo.preload(:project)
    end
  end

  def get_with_project(id) do
    Pipeline
    |> Repo.get_by(id: id)
    |> Repo.preload(:project)
  end

  def list_pipelines(project_id, user) do
    with {:ok, project} <- Projects.get_by(project_id, user) do
      project = Repo.preload(project, :pipelines)
      {:ok, project.pipelines}
    end
  end

  def run!(pipeline) do
    if pipeline.status == "pending" do
      update_pipeline(pipeline, %{status: "running"})
    end
  end

  def success!(pipeline_id) do
    pipeline =
      pipeline_id
      |> get
      |> Repo.preload([:builds, :project])

    query = from b in "builds",
            where: b.pipeline_id == ^pipeline.id and b.status == "success",
            select: count(b.id)
    successful_builds = Repo.one(query)

    query = from b in "builds",
            where: b.pipeline_id == ^pipeline.id and b.status == "failed" and b.allow_failure == true,
            select: count(b.id)
    allowed_failures = Repo.one(query)

    if (successful_builds + allowed_failures) == Enum.count(pipeline.builds) do
      Github.notify_success!(pipeline.project, pipeline)
      update_pipeline(pipeline, %{status: "success"})
      # Notify user of successfull pipeline
    end
  end

  def update_pipeline(%Pipeline{} = pipeline, params) do
    pipeline
    |> Pipeline.changeset(params)
    |> Repo.update
  end

  def update_status(pipeline_id) do
    pipeline = get(pipeline_id)

    query = from b in "builds",
            where: b.pipeline_id == ^pipeline_id and b.status in ~w(pending running success failed skipped),
            order_by: [desc: b.id], limit: 1,
            select: %{status: b.status, allow_failure: b.allow_failure}
    last_status = Repo.one(query) || %{status: "skipped", allow_failure: false}

    case last_status do
      %{status: "success"} -> success!(pipeline_id)
      %{status: "failed", allow_failure: false} -> failed!(pipeline)
      %{status: "skipped"} -> update_pipeline(pipeline, %{status: "running"})
      %{status: "running"} -> update_pipeline(pipeline, %{status: "running"})
      _ -> nil
    end
  end
end
