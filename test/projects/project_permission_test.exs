defmodule AlloyCi.ProjectPermissionTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.ProjectPermission

  @valid_attrs %{project_id: 42, repo_id: 24, user_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ProjectPermission.changeset(%ProjectPermission{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ProjectPermission.changeset(%ProjectPermission{}, @invalid_attrs)
    refute changeset.valid?
  end
end
