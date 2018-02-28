defmodule AlloyCi.Repo.Migrations.AddArtifactsAndDepsToBuild do
  use Ecto.Migration

  def change do
    alter table(:builds) do
      add(:artifacts, :map)
      add(:artifact_id, references(:artifacts))
      add(:deps, {:array, :string})
    end
  end
end
