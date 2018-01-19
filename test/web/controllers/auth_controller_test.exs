defmodule AlloyCi.Web.AuthControllerTest do
  @moduledoc """
  """
  use AlloyCi.Web.ConnCase

  import AlloyCi.Factory
  alias AlloyCi.{GuardianToken, Repo, User}

  setup do
    user_auth = insert(:user) |> with_authentication
    admin_auth = insert(:user) |> User.make_admin!() |> with_authentication

    {:ok,
     %{
       user: user_auth.user,
       admin: admin_auth.user,
       admin_auth: admin_auth,
       user_auth: user_auth
     }}
  end

  test "DELETE /logout logs out the user and admin", context do
    # This get loads the info out of the session and puts it into the connection
    conn =
      guardian_login(context.user, :token)
      |> guardian_login(context.admin, :token, key: :admin)
      |> get("/")

    assert Guardian.Plug.current_resource(conn).id == context.user.id

    {:ok, user_claims} = Guardian.Plug.claims(conn)
    user_jti = Map.get(user_claims, "jti")
    refute Repo.get_by!(GuardianToken, jti: user_jti) == nil

    # Lets visit an admin path so that we can get the admin user loaded up
    conn = get(conn, admin_user_path(conn, :index))
    assert Guardian.Plug.current_resource(conn, :admin).id == context.admin.id

    {:ok, admin_claims} = Guardian.Plug.claims(conn, :admin)
    admin_jti = Map.get(admin_claims, "jti")
    refute Repo.get_by!(GuardianToken, jti: admin_jti) == nil

    # now lets logout from the main logout and make sure they're both clear
    conn = delete(recycle(conn), "/logout")

    assert Guardian.Plug.current_resource(conn) == nil
    assert Guardian.Plug.current_resource(conn, :admin) == nil

    assert Repo.get_by(GuardianToken, jti: user_jti) == nil
    assert Repo.get_by(GuardianToken, jti: admin_jti) == nil
  end
end
