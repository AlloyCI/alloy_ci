defmodule AlloyCi.Factory do
  @moduledoc """
  """
  use ExMachina.Ecto, repo: AlloyCi.Repo

  alias AlloyCi.{User, Authentication, GuardianToken, Project, ProjectPermission}
  alias AlloyCi.{Pipeline, Build, Runner}

  def authentication_factory do
    %Authentication{
      uid: sequence(:uid, &"uid-#{&1}"),
      user: build(:user),
      provider: "identity",
      token: Comeonin.Bcrypt.hashpwsalt("sekrit")
    }
  end

  def build_factory do
    %Build{
      name: "build-1",
      commands: ["echo hello", "iex -S"],
      options: %{"variables" => %{"GITHUB" => "yes"}},
      token: sequence("long-token")
    }
  end

  def clean_pipeline_factory do
    %Pipeline{
      installation_id: sequence(:installation_id, &(&1)),
      ref: "master",
      sha: "00000000",
      before_sha: "00000000",
      commit: %{"message" => "test", "username" => "supernova32"}
    }
  end

  def clean_project_permission_factory do
    %ProjectPermission{
      repo_id: sequence(:repo_id, &(&1))
    }
  end

  def full_build_factory do
    pipeline = insert(:pipeline)
    %Build{
      name: "full-build-1",
      commands: ["mix test"],
      options: %{
        "variables" => %{"GITHUB" => "yes"},
        "services" => ["postgres:latest"],
        "before_script" => ["mix deps.get"]
      },
      stage_idx: 1,
      pipeline: pipeline,
      project: pipeline.project,
      token: sequence("long-token")
    }
  end

  def guardian_token_factory do
    %GuardianToken{
      jti: sequence(:jti, &"jti-#{&1}"),
      aud: sequence(:aud, &"aud-#{&1}")
    }
  end

  def pipeline_factory do
    project = insert(:project)
    %Pipeline{
      installation_id: sequence(:installation_id, &(&1)),
      project: project,
      ref: "master",
      sha: "00000000",
      before_sha: "00000000",
      commit: %{"message" => "test", "username" => "supernova32"},
      builds: [build(:build, project: project, status: "running")]
    }
  end

  def project_factory do
    %Project{
      name: "elixir",
      owner: "elixir-lang",
      repo_id: sequence(:repo_id, &(&1)),
      private: false,
      tags: ["elixir", "phoenix"],
      token: sequence("long-token")
    }
  end

  def project_permission_factory do
    %ProjectPermission{
      repo_id: sequence(:repo_id, &(&1)),
      project: build(:project)
    }
  end
  
  def runner_factory do
    %Runner{
      description: "test runner",
      name: "Test",
      token: sequence("long-token")
    }
  end

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

  def with_pipeline(project, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{project_id: project.id})
    insert(:clean_pipeline, attrs)
    project
  end

  def with_authentication(user, opts \\ %{}) do
    attrs = Enum.into(opts, %{user: user, uid: user.email})
    insert(:authentication, attrs)
  end
end
