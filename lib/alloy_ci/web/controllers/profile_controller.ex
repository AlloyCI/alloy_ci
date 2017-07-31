defmodule AlloyCi.Web.ProfileController do
  use AlloyCi.Web, :controller

  alias AlloyCi.{Accounts, GuardianToken, User}

  plug EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access"
  plug EnsurePermissions, [handler: AlloyCi.Web.AuthController, default: ~w(read_token)] when action in [:index]

  def index(conn, _, current_user, {:ok, %{"jti" => jti}}) do
    render conn, "index.html", current_user: current_user,
           authentications: Accounts.authentications(current_user),
           tokens: GuardianToken.for_user(current_user),
           current_jti: jti, changeset: User.changeset(current_user)
  end

  def update(conn, %{"user" => user_params}, current_user, {:ok, %{"jti" => jti}}) do
    case Accounts.update_profile(current_user, user_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Profile updated successfully.")
        |> redirect(to: profile_path(conn, :index))
      {:error, changeset} ->
        render conn, "index.html", current_user: current_user,
               authentications: Accounts.authentications(current_user),
               tokens: GuardianToken.for_user(current_user),
               current_jti: jti, changeset: changeset
    end
  end

  def delete(conn, %{"id" => id}, _, _) do
    case Accounts.delete_user(id) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Account deleted successfully.")
        |> redirect(to: profile_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, "There was an error deleting your account")
        |> redirect(to: profile_path(conn, :index))
    end
  end

  def delete(conn, %{"auth_id" => auth_id}, current_user, _) do
    case Accounts.delete_auth(auth_id, current_user) do
      {1, nil} ->
        conn
        |> put_flash(:info, "Authentication method deleted successfully.")
        |> redirect(to: profile_path(conn, :index))
      {_, _} ->
        conn
        |> put_flash(:error, "There was an error deleting your the selected authentication method")
        |> redirect(to: profile_path(conn, :index))
    end
  end
end
