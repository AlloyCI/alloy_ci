defmodule AlloyCi.GithubTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.Github
  import AlloyCi.Factory
  import Mock

  setup do
    {:ok, %{pipeline: insert(:pipeline)}}
  end

  test "clone_url/2 returns the correct data", %{pipeline: pipeline} do
    with_mock Tentacat.Integrations.Installations, [get_token: fn(_, _) -> {:ok, %{"token" => "v1.1f699f1069f60xxx"}} end] do
      result = Github.clone_url(pipeline.project, pipeline)

      assert result == "https://x-access-token:v1.1f699f1069f60xxx@github.com/elixir-lang/elixir.git"
    end
  end

  test "sha_url/2 returns the correct data", %{pipeline: pipeline} do
    result = Github.sha_url(pipeline.project, pipeline)

    assert result == "https://github.com/elixir-lang/elixir/commit/00000000"
  end

  test "domain/0 return the correct domain" do
    result = Github.domain()

    assert result == "github.com"
  end
end
