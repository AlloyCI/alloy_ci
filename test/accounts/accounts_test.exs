defmodule AlloyCi.AccountsTest do
  @moduledoc """
  """
  @lint {Credo.Check.Refactor.PipeChainStart , false}
  use AlloyCi.DataCase

  import Ecto.Query

  alias AlloyCi.Repo
  alias AlloyCi.User
  alias AlloyCi.Authentication
  alias AlloyCi.Accounts
  alias Ueberauth.Auth
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Info

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
    {:ok, user} = User.registration_changeset(%User{}, %{email: @email, name: @name}) |> Repo.insert
    {:ok, _authentication} = Authentication.changeset(
      Ecto.build_assoc(user, :authentications),
      %{
        provider: to_string(@provider),
        uid: @uid,
        token: @token,
        refresh_token: @refresh_token,
        expires_at: Guardian.Utils.timestamp + 500
      }
    ) |> Repo.insert

    before_users = user_count()
    before_authentications = authentication_count()
    {:ok, user_from_auth} = Accounts.get_or_create_user(auth, nil)
    assert user_from_auth.id == user.id

    assert user_count() == before_users
    assert authentication_count() == before_authentications
  end

  test "it returns an existing user when the user has the same email", %{auth: auth} do
    {:ok, user} = User.registration_changeset(%User{}, %{email: @email, name: @name}) |> Repo.insert
    before_users = user_count()
    before_authentications = authentication_count()
    {:ok, user_from_auth} = Accounts.get_or_create_user(auth, nil)
    assert user_from_auth.id == user.id

    assert user_count() == before_users
    assert authentication_count() == before_authentications + 1
  end

  test "it deletes the authentication and makes a new one when the old one is expired", %{auth: auth} do
    {:ok, user} = User.registration_changeset(%User{}, %{email: @email, name: @name}) |> Repo.insert
    {:ok, authentication} = Authentication.changeset(
      Ecto.build_assoc(user, :authentications),
      %{
        provider: to_string(@provider),
        uid: @uid,
        token: @token,
        refresh_token: @refresh_token,
        expires_at: Guardian.Utils.timestamp - 500
      }
    ) |> Repo.insert

    before_users = user_count()
    before_authentications = authentication_count()
    {:ok, user_from_auth} = Accounts.get_or_create_user(auth, nil)

    assert user_from_auth.id == user.id
    assert before_users == user_count()
    assert authentication_count() == before_authentications
    auth2 = Repo.one(Ecto.assoc(user, :authentications))
    refute auth2.id == authentication.id
  end

  test "it returns an error if the user is not the current user", %{auth: auth} do
    {:ok, current_user} = User.registration_changeset(%User{}, %{email: "fred@example.com", name: @name}) |> Repo.insert
    {:ok, user} = User.registration_changeset(%User{}, %{email: @email, name: @name}) |> Repo.insert
    {:ok, _authentication} = Authentication.changeset(
      Ecto.build_assoc(user, :authentications),
      %{
        provider: to_string(@provider),
        uid: @uid,
        token: @token,
        refresh_token: @refresh_token,
        expires_at: Guardian.Utils.timestamp + 500
      }
    ) |> Repo.insert

    assert {:error, :user_does_not_match} = Accounts.get_or_create_user(auth, current_user)
  end
end
