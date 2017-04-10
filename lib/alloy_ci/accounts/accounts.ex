defmodule AlloyCi.Accounts do
  @moduledoc """
  """
  alias AlloyCi.User
  alias AlloyCi.Authentication
  alias AlloyCi.Repo
  alias Ueberauth.Auth

  def get_or_create_user(auth, current_user) do
    case auth_and_validate(auth) do
      {:error, :not_found} -> register_user_from_auth(auth, current_user)
      {:error, reason} -> {:error, reason}
      authentication ->
        if authentication.expires_at && authentication.expires_at < Guardian.Utils.timestamp do
          replace_authentication(authentication, auth, current_user)
        else
          user_from_authentication(authentication, current_user)
        end
    end
  end

  def authentications(user) do
    user = user |> Repo.preload(:authentications)
    user.authentications
  end

  def current_auths(nil), do: []
  def current_auths(%User{} = user) do
    user = user |> Repo.preload(:authentications)
    user.authentications
    |> Enum.map(&(&1.provider))
  end

  # We need to check the pw for the identity provider
  defp validate_auth_for_registration(%Auth{provider: :identity} = auth) do
    pw = Map.get(auth.credentials.other, :password)
    pwc = Map.get(auth.credentials.other, :password_confirmation)
    email = auth.info.email
    case pw do
      nil ->
        {:error, :password_is_null}
      "" ->
        {:error, :password_empty}
      ^pwc ->
        validate_pw_length(pw, email)
      _ ->
        {:error, :password_confirmation_does_not_match}
    end
  end

  # All the other providers are oauth so should be good
  defp validate_auth_for_registration(_auth), do: :ok

  defp validate_pw_length(pw, email) when is_binary(pw) do
    if String.length(pw) >= 8 do
      validate_email(email)
    else
      {:error, :password_length_is_less_than_8}
    end
  end

  defp validate_email(email) when is_binary(email) do
    case Regex.run(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/, email) do
      nil ->
        {:error, :invalid_email}
      [_email] ->
        :ok
    end
  end

  defp register_user_from_auth(auth, current_user) do
    with :ok <- validate_auth_for_registration(auth) do
      case Repo.transaction(fn -> create_user_from_auth(auth, current_user) end) do
        {:ok, response} -> response
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp replace_authentication(authentication, auth, current_user) do
    with :ok <- validate_auth_for_registration(auth),
         {:ok, user} <- user_from_authentication(authentication, current_user)
    do
      case invalidate_authentication(authentication, user, auth) do
        {:ok, user} -> {:ok, user}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp invalidate_authentication(authentication, user, auth) do
    Repo.transaction(fn ->
      Repo.delete(authentication)
      authentication_from_auth(user, auth)
      user
    end)
  end

  defp user_from_authentication(authentication, current_user) do
    case Repo.one(Ecto.assoc(authentication, :user)) do
      nil -> {:error, :user_not_found}
      user ->
        if current_user && current_user.id != user.id do
          {:error, :user_does_not_match}
        else
          {:ok, user}
        end
    end
  end

  defp create_user_from_auth(auth, current_user) do
    user = current_user || Repo.get_by(User, email: auth.info.email) || create_user(auth)

    authentication_from_auth(user, auth)
    {:ok, user}
  end

  defp create_user(auth) do
    name = name_from_auth(auth)
    result =
      %User{}
      |> User.registration_changeset(scrub(%{email: auth.info.email, name: name}))
      |> Repo.insert

    case result do
      {:ok, user} -> user
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp auth_and_validate(%{provider: :identity} = auth) do
    case Repo.get_by(Authentication, uid: uid_from_auth(auth), provider: to_string(auth.provider)) do
      nil -> {:error, :wrong_credentials}
      authentication ->
        case auth.credentials.other.password do
          pass when is_binary(pass) ->
            if Comeonin.Bcrypt.checkpw(auth.credentials.other.password, authentication.token) do
              authentication
            else
              {:error, :wrong_credentials}
            end
          _ -> {:error, :password_required}
        end
    end
  end

  defp auth_and_validate(%{provider: service} = auth)  when service in [:google, :facebook, :github] do
    case Repo.get_by(Authentication, uid: uid_from_auth(auth), provider: to_string(auth.provider)) do
      nil -> {:error, :not_found}
      authentication ->
        if authentication.uid == uid_from_auth(auth) do
          authentication
        else
          {:error, :uid_mismatch}
        end
    end
  end

  defp auth_and_validate(auth) do
    case Repo.get_by(Authentication, uid: uid_from_auth(auth), provider: to_string(auth.provider)) do
      nil -> {:error, :not_found}
      authentication ->
        if authentication.token == auth.credentials.token do
          authentication
        else
          {:error, :token_mismatch}
        end
    end
  end

  defp authentication_from_auth(user, auth) do
    authentication = Ecto.build_assoc(user, :authentications)
    result =
      authentication
      |> Authentication.changeset(
          scrub(
            %{
              provider: to_string(auth.provider),
              uid: uid_from_auth(auth),
              token: token_from_auth(auth),
              refresh_token: auth.credentials.refresh_token,
              expires_at: auth.credentials.expires_at,
              password: password_from_auth(auth),
              password_confirmation: password_confirmation_from_auth(auth)
            }
          )
        )
      |> Repo.insert

    case result do
      {:ok, auth} -> auth
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp name_from_auth(auth) do
    if auth.info.name do
      auth.info.name
    else
      [auth.info.first_name, auth.info.last_name]
      |> Enum.filter(&(&1 != nil and String.strip(&1) != ""))
      |> Enum.join(" ")
    end
  end

  defp token_from_auth(%{provider: :identity} = auth) do
    case auth do
      %{credentials: %{other: %{password: pass}}} when not is_nil(pass) ->
        Comeonin.Bcrypt.hashpwsalt(pass)
      _ -> nil
    end
  end

  defp token_from_auth(auth), do: auth.credentials.token

  defp uid_from_auth(auth), do: auth.uid

  defp password_from_auth(%{provider: :identity} = auth), do: auth.credentials.other.password
  defp password_from_auth(_), do: nil

  defp password_confirmation_from_auth(%{provider: :identity} = auth) do
    auth.credentials.other.password_confirmation
  end
  defp password_confirmation_from_auth(_), do: nil

  # We don't have any nested structures in our params that we are using scrub with so this is a very simple scrub
  defp scrub(params) do
    params
    |> Enum.filter(fn
      {_key, val} when is_binary(val) -> String.strip(val) != ""
      {_key, val} when is_nil(val) -> false
      _ -> true
    end)
    |> Enum.into(%{})
  end
end
