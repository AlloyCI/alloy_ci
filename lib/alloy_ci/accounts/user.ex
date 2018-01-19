defmodule AlloyCi.User do
  @moduledoc """
  """
  use AlloyCi.Web, :schema

  alias AlloyCi.Repo

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:is_admin, :boolean)

    has_many(:authentications, AlloyCi.Authentication)
    has_many(:notifications, AlloyCi.Notification)
    has_many(:project_permissions, AlloyCi.ProjectPermission)
    has_many(:projects, through: [:project_permissions, :project])

    timestamps()
  end

  @required_fields ~w(email)a
  @optional_fields ~w(is_admin name)a

  @doc """
  Creates a changeset based on the `struct` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email, name: :users_email_index)
  end

  def make_admin!(user) do
    user
    |> cast(%{is_admin: true}, ~w(is_admin)a)
    |> Repo.update!()
  end
end
