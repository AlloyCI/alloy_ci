defmodule AlloyCi.Repo.Migrations.CreateArtifact do
  use Ecto.Migration

  def change do
    create table(:artifacts) do
      add(:build_id, references(:builds, on_delete: :delete_all, null: false))
      add(:file, :string)
      add(:expires_at, :naive_datetime)

      timestamps()
    end
  end
end
