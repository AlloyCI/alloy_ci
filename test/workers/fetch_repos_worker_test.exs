defmodule AlloyCi.FetchReposWorkerTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.Workers.FetchReposWorker

  test "it properly renders the repos from GitHub" do
    result = FetchReposWorker.rendered_content(%{uid: 765242, token: "token"}, "csrf-token")

    assert result =~ "pacman"
  end
end
