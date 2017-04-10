defmodule AlloyCi.GuardianToken do
  @moduledoc """
  """
  use AlloyCi.Web, :model

  alias AlloyCi.Repo
  alias AlloyCi.GuardianSerializer

  @primary_key {:jti, :string, []}
  @derive {Phoenix.Param, key: :jti}
  schema "guardian_tokens" do
    field :aud, :string
    field :iss, :string
    field :typ, :string
    field :sub, :string
    field :exp, :integer
    field :jwt, :string
    field :claims, :map

    timestamps()
  end

  def for_user(user) do
    case GuardianSerializer.for_token(user) do
      {:ok, aud} ->
        Repo.all(from t in AlloyCi.GuardianToken, where: t.sub == ^aud)
      _ -> []
    end
  end
end
