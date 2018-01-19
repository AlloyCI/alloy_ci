defmodule AlloyCi.Web.UserControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase
  import AlloyCi.Factory

  setup do
    {:ok, %{user1: insert(:user), user2: insert(:user)}}
  end

  describe "GET /admin/users" do
    test "without login" do
      conn = build_conn()
      conn = get(conn, admin_user_path(conn, :index))
      assert html_response(conn, 302)
    end

    test "without admin login", %{user1: user} do
      conn = guardian_login(user)
      conn = get(conn, admin_user_path(conn, :index))
      assert html_response(conn, 302)
    end

    test "with no admin logged in as an admin", %{user1: user1, user2: user2} do
      conn = guardian_login(user1, :token, key: :admin)
      conn = get(conn, admin_user_path(conn, :index))
      assert html_response(conn, 200)
      assert conn.resp_body =~ user1.email
      assert conn.resp_body =~ user2.email
    end
  end
end
