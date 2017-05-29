defmodule AlloyCi.CreateBuildsWorkerTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Build, Workers.CreateBuildsWorker}
  import AlloyCi.Factory

  setup do
    {:ok, %{pipeline: insert(:clean_pipeline, project: insert(:project))}}
  end

  test "creation of the correct builds", %{pipeline: pipeline} do
    CreateBuildsWorker.perform(pipeline.id)
    build = Repo.one(from b in Build, order_by: [desc: b.id], limit: 1)

    assert build.name == "mix"
    assert build.commands == ["mix test"]
    assert build.project_id == pipeline.project_id
    assert build.when == "on_success"
    assert build.tags == ["elixir", "postgres"]
  end
end
