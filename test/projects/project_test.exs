defmodule AlloyCi.ProjectTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.Project

  @valid_attrs %{
    owner: "some_owner",
    name: "some content",
    private: true,
    repo_id: 42,
    token: "long-token"
  }
  @invalid_attrs %{repo_id: nil}

  test "changeset with valid attributes" do
    changeset = Project.changeset(%Project{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Project.changeset(%Project{}, @invalid_attrs)
    refute changeset.valid?
  end
end
