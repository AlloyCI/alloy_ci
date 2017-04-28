defmodule AlloyCi.Runner do
  @moduledoc """
  """
  use Ecto.Schema

  schema "runners" do
    field :active, :boolean, default: false
    field :architecture, :string
    field :contacted_at, :naive_datetime
    field :description, :string
    field :global, :boolean, default: false
    field :locked, :boolean, default: false
    field :name, :string
    field :platform, :string
    field :project_id, :integer
    field :token, :string
    field :tags, {:array, :string}
    field :version, :string

    timestamps()
  end
end
