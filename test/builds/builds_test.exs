defmodule AlloyCi.BuildsTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.{Build, Builds, Repo}
  import AlloyCi.Factory

  test "create_builds_from_config/2 creates build with the correct data" do
    content = File.read!(".alloy-ci.json")
    pipeline = insert(:pipeline)

    {:ok, result} = Builds.create_builds_from_config(content, pipeline)

    assert result == nil

    build = Repo.one(from b in Build, order_by: [desc: b.id], limit: 1)

    assert build.name == "mix"
    assert build.commands == ["mix test"]
    assert build.project_id == pipeline.project_id
    assert build.when == "on_success"
  end
end
