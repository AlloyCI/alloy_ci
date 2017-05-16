defmodule AlloyCi.AuthenticationTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  alias AlloyCi.Authentication

  @valid_attrs %{provider: "some content", uid: "some content", user_id: 42, token: "some token"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Authentication.changeset(%Authentication{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Authentication.changeset(%Authentication{}, @invalid_attrs)
    refute changeset.valid?
  end
end
