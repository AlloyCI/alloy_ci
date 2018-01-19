defmodule AlloyCi.Repo.Migrations.CreateAuthentication do
  @moduledoc """
  """
  use Ecto.Migration

  def change do
    create table(:authentications) do
      add(:provider, :string)
      add(:uid, :string)
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:token, :text)
      add(:refresh_token, :text)
      add(:expires_at, :bigint)

      timestamps()
    end

    create(index(:authentications, [:provider, :uid], unique: true))
    create(index(:authentications, [:expires_at]))
    create(index(:authentications, [:provider, :token]))
  end
end
