defmodule AlloyCi.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :acknowledged, :boolean, default: false
      add :content, :map, null: false
      add :notification_type, :string, null: false, default: "pipeline_failed"
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
