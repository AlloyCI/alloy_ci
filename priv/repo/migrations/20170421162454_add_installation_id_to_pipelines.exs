defmodule AlloyCi.Repo.Migrations.AddInstallationIdToPipelines do
  @moduledoc """
  """
  use Ecto.Migration

  def change do
    alter table(:pipelines) do
      add :installation_id, :integer, null: false
    end
  end
end
