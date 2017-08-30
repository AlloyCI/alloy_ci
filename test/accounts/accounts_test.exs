defmodule AlloyCi.AccountsTest do
  @moduledoc """
  """
  use AlloyCi.DataCase
  import Ecto.Query

  alias AlloyCi.{Accounts, Authentication, User, Repo}
  alias Ueberauth.Auth
  alias Ueberauth.Auth.{Credentials, Info}

  @name "Bob Belcher"
  @email "bob@gmail.com"
  @uid "bob"
  @provider :github
  @token "the-token"
  @refresh_token "refresh-token"

  setup do
    auth = %Auth{
      uid: @uid,
      provider: @provider,
      info: %Info{
        name: @name,
        email: @email,
      },
      credentials: %Credentials{
        token: @token,
        refresh_token: "refresh-token",
        expires_at: Guardian.Utils.timestamp + 1000,
      }
    }
    {:ok, %{auth: auth, repo: Repo}}
  end

  def user_count, do: Repo.one(from u in User, select: count(u.id))
  def authentication_count, do: Repo.one(from a in Authentication, select: count(a.id))

  test "it creates a new authentication and user when there is neither", %{auth: auth} do
    before_users = user_count()
    before_authentications = authentication_count()
    {:ok, user} = Accounts.get_or_create_user(auth, nil)
    after_users = user_count()
    after_authentications = authentication_count()

    assert after_users == (before_users + 1)
    assert after_authentications == (before_authentications + 1)
    assert user.email == @email
  end

  test "it returns the existing user when the authentication and user both exist", %{auth: auth} do
    {:ok, user} =
      %User{}
      |> User.changeset(%{email: @email, name: @name})
      |> Repo.insert

    params = %{
      provider: to_string(@provider),
      uid: @uid,
      token: @token,
      refresh_token: @refresh_token,
      expires_at: Guardian.Utils.timestamp + 500
    }
    {:ok, _} =
      user
      |> Ecto.build_assoc(:authentications)
      |> Authentication.changeset(params)
      |> Repo.insert

    before_users = user_count()
    before_authentications = authentication_count()
    {:ok, user_from_auth} = Accounts.get_or_create_user(auth, nil)
    assert user_from_auth.id == user.id

    assert user_count() == before_users
    assert authentication_count() == before_authentications
  end

  test "it returns an error when the user has the same email and it is not logged in", %{auth: auth} do
    {:ok, _} =
      %User{}
      |> User.changeset(%{email: @email, name: @name})
      |> Repo.insert

    before_users = user_count()
    before_authentications = authentication_count()
    assert {:error, _} = Accounts.get_or_create_user(auth, nil)

    assert user_count() == before_users
    assert authentication_count() == before_authentications
  end

  test "it creates a new auth when user is already logged in", %{auth: auth} do
    {:ok, current_user} =
      %User{}
      |> User.changeset(%{email: @email, name: @name})
      |> Repo.insert

    before_users = user_count()
    before_authentications = authentication_count()
    assert {:ok, user} = Accounts.get_or_create_user(auth, current_user)
    assert user.id == current_user.id

    assert user_count() == before_users
    assert authentication_count() == before_authentications + 1
  end

  test "it updates the existing authentication when expired", %{auth: auth} do
    {:ok, user} =
      %User{}
      |> User.changeset(%{email: @email, name: @name})
      |> Repo.insert

    params = %{
      provider: to_string(@provider),
      uid: @uid,
      token: @token,
      refresh_token: @refresh_token,
      expires_at: Guardian.Utils.timestamp - 500
    }

    {:ok, authentication} =
      user
      |> Ecto.build_assoc(:authentications)
      |> Authentication.changeset(params)
      |> Repo.insert

    before_users = user_count()
    before_authentications = authentication_count()
    {:ok, user_from_auth} = Accounts.get_or_create_user(auth, nil)

    assert user_from_auth.id == user.id
    assert before_users == user_count()
    assert authentication_count() == before_authentications
    auth2 = Repo.one(Ecto.assoc(user, :authentications))
    assert auth2.id == authentication.id
  end

  test "it returns an error if the user is not the current user", %{auth: auth} do
    {:ok, current_user} =
      %User{}
      |> User.changeset(%{email: "fred@example.com", name: @name})
      |> Repo.insert

    {:ok, user} =
      %User{}
      |> User.changeset(%{email: @email, name: @name})
      |> Repo.insert


    params = %{
      provider: to_string(@provider),
      uid: @uid,
      token: @token,
      refresh_token: @refresh_token,
      expires_at: Guardian.Utils.timestamp + 500
    }

    {:ok, _} =
      user
      |> Ecto.build_assoc(:authentications)
      |> Authentication.changeset(params)
      |> Repo.insert

    assert {:error, :user_does_not_match} = Accounts.get_or_create_user(auth, current_user)
  end
end
