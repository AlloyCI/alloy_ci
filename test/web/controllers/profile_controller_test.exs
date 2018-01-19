defmodule AlloyCi.Web.ProfileControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  import AlloyCi.Factory

  setup do
    {:ok, %{user: insert(:user)}}
  end

  test "GET /profile without permission", %{user: user} do
    conn =
      user
      |> guardian_login
      |> get("/profile")

    assert html_response(conn, 302)
  end

  test "GET /profile with permission", %{user: user} do
    conn =
      user
      |> guardian_login(:access, perms: %{default: [:read_token]})
      |> get("/profile")

    assert html_response(conn, 200)
  end

  test "UPDATE /profile", %{user: user} do
    conn =
      user
      |> guardian_login(:access, perms: %{default: [:read_token]})
      |> put("/profile/1", %{"user" => %{"name" => "new name"}})

    assert html_response(conn, 302)
  end

  test "DELETE /profile for user", %{user: user} do
    conn =
      user
      |> guardian_login(:access, perms: %{default: [:read_token]})
      |> delete("/profile/#{user.id}")

    assert html_response(conn, 302)
  end

  test "DELETE /profile for auth", %{user: user} do
    auth = insert(:authentication, user: user)

    conn =
      user
      |> guardian_login(:access, perms: %{default: [:read_token]})
      |> delete("/profile/#{auth.id}/delete")

    assert html_response(conn, 302)
  end
end
