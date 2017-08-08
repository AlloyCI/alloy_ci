defmodule AlloyCi.Repo.Migrations.CreateInstallation do
  use Ecto.Migration

  def change do
    create table(:installations) do
      add :login, :string, null: false
      add :target_id, :integer, null: false
      add :target_type, :string, null: false
      add :uid, :integer, null: false

      timestamps()
    end

    create index(:installations, [:target_id], unique: true)
    create index(:installations, [:uid], unique: true)
  end
end
