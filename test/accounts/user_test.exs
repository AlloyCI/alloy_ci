defmodule AlloyCi.UserTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.User

  @valid_attrs %{name: "some content", email: "foo@example.com"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
