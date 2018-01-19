defmodule AlloyCi.Authentication do
  @moduledoc """
  An Authentication struct represents a set of credentials with which a
  User can gain access to the system.
  """
  use AlloyCi.Web, :schema

  schema "authentications" do
    field(:provider, :string)
    field(:uid, :string)
    field(:token, :string)
    field(:refresh_token, :string)
    field(:expires_at, :integer)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    belongs_to(:user, AlloyCi.User)

    timestamps()
  end

  @required_fields ~w(provider uid user_id token)a
  @optional_fields ~w(refresh_token expires_at)a

  @doc """
  Creates a changeset based on the `struct` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:provider_uid)
  end
end
