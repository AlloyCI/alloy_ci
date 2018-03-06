defmodule AlloyCi.Web.ProfileController do
  use AlloyCi.Web, :controller

  alias AlloyCi.{Accounts, GuardianToken, User}

  plug(EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access")

  def index(conn, _, current_user, %{"jti" => jti}) do
    render(
      conn,
      "index.html",
      current_user: current_user,
      authentications: Accounts.authentications(current_user),
      tokens: GuardianToken.for_user(current_user),
      current_jti: jti,
      changeset: User.changeset(current_user)
    )
  end

  def update(conn, %{"user" => user_params}, current_user, %{"jti" => jti}) do
    with {:ok, _} <- Accounts.update_profile(current_user, user_params) do
      conn
      |> put_flash(:info, "Profile updated successfully.")
      |> redirect(to: profile_path(conn, :index))
    else
      {:error, changeset} ->
        render(
          conn,
          "index.html",
          current_user: current_user,
          authentications: Accounts.authentications(current_user),
          tokens: GuardianToken.for_user(current_user),
          current_jti: jti,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}, _, _) do
    with {:ok, _} <- Accounts.delete_user(id) do
      conn
      |> put_flash(:info, "Account deleted successfully.")
      |> redirect(to: profile_path(conn, :index))
    else
      {:error, _} ->
        conn
        |> put_flash(:error, "There was an error deleting your account")
        |> redirect(to: profile_path(conn, :index))
    end
  end

  def delete(conn, %{"auth_id" => auth_id}, current_user, _) do
    with {1, nil} <- Accounts.delete_auth(auth_id, current_user) do
      conn
      |> put_flash(:info, "Authentication method deleted successfully.")
      |> redirect(to: profile_path(conn, :index))
    else
      {_, _} ->
        conn
        |> put_flash(
          :error,
          "There was an error deleting your the selected authentication method"
        )
        |> redirect(to: profile_path(conn, :index))
    end
  end
end
