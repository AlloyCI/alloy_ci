defmodule AlloyCi.Factory do
  @moduledoc """
  """
  use ExMachina.Ecto, repo: AlloyCi.Repo

  alias AlloyCi.User
  alias AlloyCi.Authentication
  alias AlloyCi.GuardianToken
  alias AlloyCi.Project
  alias AlloyCi.ProjectPermission

  def user_factory do
    %User{
      name: "Bob Belcher",
      email: sequence(:email, &"email-#{&1}@example.com"),
    }
  end

  def user_with_project_factory do
    %User{
      name: "Bob Belcher",
      email: sequence(:email, &"email-#{&1}@example.com"),
      project_permissions: [build(:project_permission)]
    }
  end

  def project_permission_factory do
    %ProjectPermission{
      repo_id: sequence(:repo_id, &(&1)),
      project: build(:project)
    }
  end

  def project_factory do
    %Project{
      name: "elixir",
      owner: "elixir-lang",
      repo_id: sequence(:repo_id, &(&1)),
      private: false
    }
  end

  def guardian_token_factory do
    %GuardianToken{
      jti: sequence(:jti, &"jti-#{&1}"),
      aud: sequence(:aud, &"aud-#{&1}")
    }
  end

  def authentication_factory do
    %Authentication{
      uid: sequence(:uid, &"uid-#{&1}"),
      user: build(:user),
      provider: "identity",
      token: Comeonin.Bcrypt.hashpwsalt("sekrit")
    }
  end

  def with_authentication(user, opts \\ []) do
    opts = opts ++ [user: user, uid: user.email]
    insert(:authentication, opts)
  end
end
