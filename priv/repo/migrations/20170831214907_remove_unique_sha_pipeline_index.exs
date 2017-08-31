defmodule AlloyCi.Repo.Migrations.RemoveUniqueShaPipelineIndex do
  use Ecto.Migration

  def change do
    drop index(:pipelines, [:project_id, :sha])
  end
end
