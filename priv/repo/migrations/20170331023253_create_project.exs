defmodule AlloyCi.Repo.Migrations.CreateProject do
  @moduledoc """
  """
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :owner, :string, null: false
      add :private, :boolean, default: false, null: false
      add :repo_id, :integer, null: false
      add :tags, {:array, :string}
      add :token, :string, null: false

      timestamps()
    end

    create index(:projects, [:repo_id], unique: true)
    create index(:projects, [:token], unique: true)
  end
end
