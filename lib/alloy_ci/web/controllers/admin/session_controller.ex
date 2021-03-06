defmodule AlloyCi.Web.Admin.SessionController do
  @moduledoc """
  Provides login and logout for the admin part of the site.
  We keep the logins separate rather than use a permission for this because
  keeping the tokens in separate locations allows us to more easily manage the
  different requirements between the normal site and the admin site
  """
  use AlloyCi.Web, :admin_controller

  alias AlloyCi.{Accounts, Guardian}

  # We still want to use Ueberauth for checking the passwords etc
  # we have everything we need to check email / passwords and OAuth already
  # but we only want to provide access for folks using email/pass
  plug(Ueberauth, base_path: "/admin/auth", providers: [:identity])
  plug(:put_layout, "login_layout.html")

  # Make sure that we have a valid token in the :admin area of the session
  # We've aliased Guardian.Plug.EnsureAuthenticated in our AlloyCi.Web.admin_controller macro
  plug(
    EnsureAuthenticated,
    [key: :admin, handler: __MODULE__] when action in [:delete, :impersonate, :stop_impersonating]
  )

  def new(conn, _params, current_user, _claims) do
    render(conn, "new.html", current_user: current_user)
  end

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params, current_user, _claims) do
    conn
    |> put_flash(:error, hd(fails.errors).message)
    |> render("new.html", current_user: current_user)
  end

  # In this function, when sign in is successful we sign_in the user into the :admin section
  # of the Guardian session
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params, current_user, _claims) do
    case Accounts.get_or_create_user(auth, current_user) do
      {:ok, user} ->
        if user.is_admin do
          conn
          |> put_flash(:success, "Signed in as #{user.name}")
          |> Guardian.Plug.sign_in(user, %{typ: "access"}, key: :admin)
          |> redirect(to: admin_user_path(conn, :index))
        else
          conn
          |> put_flash(:error, "Unauthorized")
          |> redirect(to: admin_login_path(conn, :new))
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not authenticate")
        |> render("new.html", current_user: current_user)
    end
  end

  def logout(conn, _params, _current_user, _claims) do
    conn
    |> Guardian.Plug.sign_out(key: :admin)
    |> put_flash(:info, "admin signed out")
    |> redirect(to: "/")
  end

  def impersonate(conn, %{"user_id" => user_id}, _current_user, _claims) do
    user = Accounts.get_user(user_id)

    conn
    |> Guardian.Plug.sign_out(key: :default)
    |> Guardian.Plug.sign_in(user, %{typ: "access"})
    |> redirect(to: project_path(conn, :index))
  end

  def stop_impersonating(conn, _params, _current_user, _claims) do
    conn
    |> Guardian.Plug.sign_out(key: :default)
    |> redirect(to: admin_user_path(conn, :index))
  end
end
