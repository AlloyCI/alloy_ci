defmodule AlloyCi.Installation do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "installations" do
    field(:login, :string, null: false)
    field(:target_id, :integer, null: false)
    field(:target_type, :string, null: false)
    field(:uid, :integer, null: false)

    timestamps()
  end

  @required_fields ~w(login target_id target_type uid)a

  @doc """
  Creates a changeset based on the `struct` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
