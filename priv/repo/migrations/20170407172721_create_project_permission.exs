defmodule AlloyCi.Repo.Migrations.CreateProjectPermission do
  @moduledoc """
  """
  use Ecto.Migration

  def change do
    create table(:project_permissions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :repo_id, :integer, null: false

      timestamps()
    end

    create index(:project_permissions, [:user_id, :project_id], unique: true)
  end
end
