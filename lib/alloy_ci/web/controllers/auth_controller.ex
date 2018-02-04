defmodule AlloyCi.Web.AuthController do
  @moduledoc """
  Handles the Ueberauth integration.
  This controller implements the request and callback phases for all providers.
  The actual creation and lookup of users/authentications is handled by Accounts
  """
  use AlloyCi.Web, :controller

  alias AlloyCi.Accounts

  plug(Ueberauth)
  plug(:put_layout, "login_layout.html")

  def login(conn, _params, current_user, _claims) do
    auths = Accounts.current_auths(current_user)

    if Enum.count(auths) > 1 do
      redirect(conn, to: project_path(conn, :index))
    else
      render(
        conn,
        "login.html",
        current_user: current_user,
        current_auths: auths
      )
    end
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params, current_user, _claims) do
    conn
    |> put_flash(:error, hd(fails.errors).message)
    |> render(
      "login.html",
      current_user: current_user,
      current_auths: Accounts.current_auths(current_user)
    )
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params, current_user, _claims) do
    case Accounts.get_or_create_user(auth, current_user) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Signed in as #{user.name}")
        |> Guardian.Plug.sign_in(user, :access, perms: %{default: Guardian.Permissions.max()})
        |> redirect(to: project_path(conn, :index))

      {:error, reason} ->
        conn
        |> put_flash(:error, "Could not authenticate. Error: #{reason}")
        |> render(
          "login.html",
          current_user: current_user,
          current_auths: Accounts.current_auths(current_user)
        )
    end
  end

  def logout(conn, _params, current_user, _claims) do
    if current_user do
      conn
      |> Guardian.Plug.sign_out()
      |> put_flash(:info, "Signed out")
      |> redirect(to: "/")
    else
      conn
      |> put_flash(:info, "Not logged in")
      |> redirect(to: "/")
    end
  end

  # Authentication handler functions
  def unauthenticated(conn, _params) do
    conn
    |> put_flash(:error, "Authentication required")
    |> redirect(to: auth_path(conn, :login, :login))
  end

  def unauthorized(conn, _params) do
    conn
    |> put_flash(:error, "Unauthorized")
    |> redirect(external: redirect_back(conn))
  end
end
