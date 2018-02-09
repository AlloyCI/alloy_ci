defmodule AlloyCi.Repo.Migrations.AddSecretVarsToProject do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add(:secret_variables, :map)
    end
  end
end
