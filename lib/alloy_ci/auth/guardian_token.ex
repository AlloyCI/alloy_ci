defmodule AlloyCi.GuardianToken do
  @moduledoc """
  JWT Tokens used for authentication. They are stored in DB in order to make
  it easier to revoke them.
  """
  use Ecto.Schema
  import Ecto.Query

  alias AlloyCi.{Guardian, Repo}

  @primary_key {:jti, :string, []}
  @derive {Phoenix.Param, key: :jti}
  schema "guardian_tokens" do
    field(:aud, :string)
    field(:iss, :string)
    field(:typ, :string)
    field(:sub, :string)
    field(:exp, :integer)
    field(:jwt, :string)
    field(:claims, :map)

    timestamps()
  end

  @spec for_user(User.t()) :: any()
  def for_user(user) do
    case Guardian.subject_for_token(user, nil) do
      {:ok, aud} ->
        Repo.all(from(t in AlloyCi.GuardianToken, where: t.sub == ^aud))

      _ ->
        []
    end
  end
end
