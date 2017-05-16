defmodule AlloyCi.GuardianToken do
  @moduledoc """
  JWT Tokens used for authetication. They are stored in DB in order to make
  it easier to revoke them.
  """
  use AlloyCi.Web, :model

  alias AlloyCi.{GuardianSerializer, Repo}

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
