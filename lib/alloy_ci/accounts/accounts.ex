defmodule AlloyCi.Accounts do
  @moduledoc """
  The boundary for the Accounts system.
  """
  alias AlloyCi.{Authentication, Installation, ProjectPermission, Queuer, Repo, User}
  alias AlloyCi.Workers.CreatePermissionsWorker
  alias Ueberauth.Auth
  import Ecto.Query

  @spec authentications(User.t()) :: [Authentication.t()]
  def authentications(user) do
    user = user |> Repo.preload(:authentications)
    user.authentications
  end

  @spec create_installation(map()) :: {:error, any()} | {:ok, Installation.t()}
  def create_installation(params) do
    %Installation{}
    |> Installation.changeset(params)
    |> Repo.insert()
  end

  @spec installed_on_owner?(any()) :: boolean()
  def installed_on_owner?(target_id) do
    result =
      Installation
      |> where(target_id: ^target_id)
      |> limit(1)
      |> Repo.one()

    case result do
      nil -> false
      _ -> true
    end
  end

  @spec current_auths(nil | User.t()) :: [any()]
  def current_auths(nil), do: []

  def current_auths(%User{} = user) do
    user = user |> Repo.preload(:authentications)

    user.authentications
    |> Enum.map(& &1.provider)
  end

  @spec delete_auth(any(), User.t()) :: any()
  def delete_auth(id, user) do
    Authentication
    |> where(id: ^id, user_id: ^user.id)
    |> Repo.delete_all()
  end

  @spec delete_auths(any()) :: any()
  def delete_auths(user_id) do
    Authentication
    |> where(user_id: ^user_id)
    |> Repo.delete_all()
  end

  @spec delete_installation(any()) :: any()
  def delete_installation(uid) do
    Installation
    |> where(uid: ^uid)
    |> Repo.delete_all()
  end

  @spec delete_user(any()) :: {:error, any()} | {:ok, User.t()}
  def delete_user(id) do
    query =
      ProjectPermission
      |> where(user_id: ^id)

    with {_, nil} <- Repo.delete_all(query),
         {_, nil} <- delete_auths(id) do
      id |> get_user() |> Repo.delete()
    else
      _ ->
        {:error, nil}
    end
  end

  @spec get_or_create_user(atom() | %{provider: any(), uid: any()}, any()) :: User.t()
  def get_or_create_user(auth, current_user) do
    case auth_and_validate(auth) do
      {:error, :not_found} ->
        register_user_from_auth(auth, current_user)

      {:error, reason} ->
        {:error, reason}

      authentication ->
        if authentication.expires_at && authentication.expires_at < Timex.now() do
          replace_authentication(authentication, auth, current_user)
        else
          user_from_authentication(authentication, current_user)
        end
    end
  end

  @spec get_user(any()) :: User.t()
  def get_user(id), do: User |> Repo.get(id)

  @spec get_user_id_from_auth_token(binary()) :: pos_integer()
  def get_user_id_from_auth_token(token) do
    query = from(a in Authentication, where: a.token == ^token, limit: 1, select: a.user_id)
    Repo.one(query)
  end

  @spec get_valid_auth_token(User.t()) :: binary()
  def get_valid_auth_token(user) do
    query = from(a in Authentication, where: a.user_id == ^user.id, limit: 1, select: a.token)
    Repo.one(query)
  end

  @spec github_auth(User.t()) :: Authentication.t()
  def github_auth(user) do
    Authentication
    |> where(user_id: ^user.id)
    |> where(provider: "github")
    |> Repo.one()
  end

  @spec gravatar_url(User.t()) :: binary()
  def gravatar_url(user) do
    user.email
    |> Gravatar.new()
    |> Gravatar.secure()
    |> to_string
  end

  @doc """
  Process the current auth, and enqueues a worker that creates the proper
  project permissions for projects to which the user already has access,
  and have already been added to AlloyCI.
  """
  @spec process_auth(Authentication.t()) :: Authentication.t()
  def process_auth(auth) do
    case auth.provider do
      "github" ->
        Queuer.push(CreatePermissionsWorker, {auth.user_id, auth.token})
        auth

      _ ->
        auth
    end
  end

  @spec update_profile(User.t(), map()) :: {:error, any()} | {:ok, User.t()}
  def update_profile(user, user_params) do
    user
    |> User.changeset(user_params)
    |> Repo.update()
  end

  ###################
  # Private functions
  ###################
  defp auth_and_validate(%{provider: :identity} = auth) do
    case Authentication
         |> Repo.get_by(uid: uid_from_auth(auth), provider: to_string(auth.provider)) do
      nil ->
        {:error, :not_found}

      authentication ->
        case auth.credentials.other.password do
          pass when is_binary(pass) ->
            if Comeonin.Bcrypt.checkpw(auth.credentials.other.password, authentication.token) do
              authentication
            else
              {:error, :invalid_credentials}
            end

          _ ->
            {:error, :password_required}
        end
    end
  end

  defp auth_and_validate(%{provider: service} = auth)
       when service in [:google, :facebook, :github] do
    case Authentication
         |> Repo.get_by(uid: uid_from_auth(auth), provider: to_string(auth.provider)) do
      nil ->
        {:error, :not_found}

      authentication ->
        if authentication.uid == uid_from_auth(auth) do
          update_authentication(authentication, auth)
        else
          {:error, :uid_mismatch}
        end
    end
  end

  defp auth_and_validate(auth) do
    case Authentication
         |> Repo.get_by(uid: uid_from_auth(auth), provider: to_string(auth.provider)) do
      nil ->
        {:error, :not_found}

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
        scrub(%{
          provider: to_string(auth.provider),
          uid: uid_from_auth(auth),
          token: token_from_auth(auth),
          refresh_token: auth.credentials.refresh_token,
          expires_at: auth.credentials.expires_at,
          password: password_from_auth(auth),
          password_confirmation: password_confirmation_from_auth(auth)
        })
      )
      |> Repo.insert()

    case result do
      {:ok, auth} ->
        process_auth(auth)

      {:error, reason} ->
        Repo.rollback(reason)
    end
  end

  defp create_user(auth) do
    name = name_from_auth(auth)

    result =
      %User{}
      |> User.changeset(scrub(%{email: auth.info.email, name: name}))
      |> Repo.insert()

    case result do
      {:ok, user} ->
        user

      {:error, reason} ->
        Repo.rollback(reason)
    end
  end

  defp create_user_from_auth(auth, current_user) do
    user = current_user || create_user(auth)

    authentication_from_auth(user, auth)
    {:ok, user}
  end

  defp error_details({message, values}) do
    Enum.reduce(values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end

  defp invalidate_authentication(authentication, user, auth) do
    Repo.transaction(fn ->
      Repo.delete(authentication)
      authentication_from_auth(user, auth)
      user
    end)
  end

  defp name_from_auth(auth) do
    cond do
      auth.info.name ->
        auth.info.name

      auth.info.first_name && auth.info.last_name ->
        [auth.info.first_name, auth.info.last_name]
        |> Enum.filter(&(&1 != nil and String.trim(&1) != ""))
        |> Enum.join(" ")

      auth.info.nickname ->
        auth.info.nickname

      true ->
        auth.info.email
    end
  end

  defp password_from_auth(%{provider: :identity} = auth), do: auth.credentials.other.password
  defp password_from_auth(_), do: nil

  defp password_confirmation_from_auth(%{provider: :identity} = auth) do
    auth.credentials.other.password_confirmation
  end

  defp password_confirmation_from_auth(_), do: nil

  defp register_user_from_auth(auth, current_user) do
    with :ok <- validate_auth_for_registration(auth) do
      case Repo.transaction(fn -> create_user_from_auth(auth, current_user) end) do
        {:ok, response} ->
          response

        {:error, changeset} ->
          reason =
            Enum.map(changeset.errors, fn {field, detail} ->
              "#{field} #{error_details(detail)}"
            end)

          {:error, reason}
      end
    end
  end

  defp replace_authentication(authentication, auth, current_user) do
    with :ok <- validate_auth_for_registration(auth),
         {:ok, user} <- user_from_authentication(authentication, current_user) do
      invalidate_authentication(authentication, user, auth)
    end
  end

  # We don't have any nested structures in our params that we are using scrub
  # with so this is a very simple scrub
  defp scrub(params) do
    params
    |> Enum.filter(fn
      {_key, val} when is_binary(val) -> String.trim(val) != ""
      {_key, val} when is_nil(val) -> false
      _ -> true
    end)
    |> Enum.into(%{})
  end

  defp token_from_auth(%{provider: :identity} = auth) do
    case auth do
      %{credentials: %{other: %{password: pass}}} when not is_nil(pass) ->
        Comeonin.Bcrypt.hashpwsalt(pass)

      _ ->
        nil
    end
  end

  defp token_from_auth(auth), do: auth.credentials.token

  defp update_authentication(authentication, auth) do
    result =
      authentication
      |> Authentication.changeset(
        scrub(%{
          provider: to_string(auth.provider),
          uid: uid_from_auth(auth),
          token: token_from_auth(auth),
          refresh_token: auth.credentials.refresh_token,
          expires_at: auth.credentials.expires_at
        })
      )
      |> Repo.update()

    case result do
      {:ok, authentication} -> authentication
      {:error, _} -> {:error, :uid_mismatch}
    end
  end

  defp user_from_authentication(authentication, current_user) do
    case Repo.one(Ecto.assoc(authentication, :user)) do
      nil ->
        {:error, :user_not_found}

      user ->
        if current_user && current_user.id != user.id do
          {:error, :user_does_not_match}
        else
          {:ok, user}
        end
    end
  end

  defp uid_from_auth(auth), do: to_string(auth.uid)

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

      value when pwc and value != pwc ->
        {:error, :password_confirmation_does_not_match}

      _ ->
        {:error, :invalid_credentials}
    end
  end

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
      nil -> {:error, :invalid_email}
      [_email] -> :ok
    end
  end
end
