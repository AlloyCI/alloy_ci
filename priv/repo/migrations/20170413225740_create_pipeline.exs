defmodule AlloyCi.Repo.Migrations.CreatePipeline do
  @moduledoc """
  """
  use Ecto.Migration

  def change do
    create table(:pipelines) do
      add :before_sha, :string
      add :commit, :map, null: false
      add :duration, :integer
      add :finished_at, :naive_datetime
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :ref, :string, null: false
      add :sha, :string, null: false
      add :started_at, :naive_datetime
      add :status, :string, default: "pending"

      timestamps()
    end

    create unique_index(:pipelines, [:project_id, :sha])
    create index(:pipelines, [:project_id])
  end
end
