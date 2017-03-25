defmodule AlloyCi.AuthorizationTest do
  use AlloyCi.ModelCase

  alias AlloyCi.Authorization

  @valid_attrs %{provider: "some content", uid: "some content", user_id: 42, token: "some token"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Authorization.changeset(%Authorization{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Authorization.changeset(%Authorization{}, @invalid_attrs)
    refute changeset.valid?
  end
end
