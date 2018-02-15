defmodule AlloyCi.Repo.Migrations.AddNotifiedToPipeline do
  use Ecto.Migration

  def change do
    alter table(:pipelines) do
      add(:notified, :boolean, default: false)
    end
  end
end
