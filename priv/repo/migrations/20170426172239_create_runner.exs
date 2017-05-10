defmodule AlloyCi.Repo.Migrations.CreateAlloyCi.Runner do
  @moduledoc """
  """
  use Ecto.Migration

  def change do
    create table(:runners) do
      add :active, :boolean, default: true, null: false
      add :architecture, :string
      add :contacted_at, :naive_datetime
      add :description, :string
      add :global, :boolean, default: true, null: false
      add :locked, :boolean, default: false, null: false
      add :name, :string
      add :run_untagged, :boolean, default: true, null: false
      add :platform, :string
      add :project_id, :integer
      add :tags, {:array, :string}
      add :token, :string, null: false
      add :version, :string

      timestamps()
    end

  end
end
