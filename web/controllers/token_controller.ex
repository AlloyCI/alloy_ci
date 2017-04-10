defmodule AlloyCi.TokenController do
  use AlloyCi.Web, :controller

  alias AlloyCi.GuardianToken

  plug EnsureAuthenticated, handler: AlloyCi.AuthController, typ: "access"
  plug EnsurePermissions, [handler: AlloyCi.AuthController, default: ~w(read_token)] when action in [:index]
  plug EnsurePermissions, [handler: AlloyCi.AuthController, default: ~w(revoke_token)] when action in [:delete]

  def index(conn, _params, current_user, {:ok, %{"jti" => jti}}) do
    render conn,
           "index.html",
           current_user: current_user,
           tokens: GuardianToken.for_user(current_user),
           current_jti: jti
  end

  def delete(conn, %{"id" => jti}, current_user, _claims) do
    case Repo.get(GuardianToken, jti) do
      nil -> could_not_delete(conn)
      token ->
        with {:ok, _} <- Repo.delete(token) do
          {:ok, sub} = AlloyCi.GuardianSerializer.for_token(current_user)
          if sub == token.sub do
            conn
            |> put_flash(:info, "Done")
            |> redirect(to: token_path(conn, :index))
          else
            could_not_delete(conn)
          end
        else
          {:error, _} -> could_not_delete(conn)
        end
    end
  end

  defp could_not_delete(conn) do
    conn
    |> put_flash(:error, "Could not delete")
    |> redirect(external: redirect_back(conn))
  end
end
