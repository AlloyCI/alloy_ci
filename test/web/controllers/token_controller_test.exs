defmodule AlloyCi.Web.TokenControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  import AlloyCi.Factory
  alias AlloyCi.{GuardianToken, Repo}

  setup do
    {:ok, %{user: insert(:user)}}
  end

  test "DELETE /tokens/:jti with no login should fail" do
    token = insert(:guardian_token)
    conn = build_conn()
    conn = delete(conn, token_path(conn, :delete, token.jti))

    assert html_response(conn, 302)
    assert Repo.get(GuardianToken, token.jti).jti == token.jti
  end

  test "DELETE /tokens/:jti without revoke permission should fail", %{user: user} do
    token = insert(:guardian_token)

    conn =
      user
      |> guardian_login(:access)
      |> delete(token_path(build_conn(), :delete, token.jti))

    assert html_response(conn, 302)

    new_token = Repo.get(GuardianToken, token.jti)
    refute new_token == nil
    assert new_token.jti == token.jti
  end

  test "DELETE /tokens/:jti without revoke permission should be cool", %{user: user} do
    token = insert(:guardian_token)

    user
    |> guardian_login(:access, perms: %{default: [:revoke_token]})
    |> delete(token_path(build_conn(), :delete, token.jti))

    new_token = Repo.get(GuardianToken, token.jti)
    assert new_token == nil
  end
end
