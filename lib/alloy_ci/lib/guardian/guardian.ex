defmodule AlloyCi.Guardian do
  @moduledoc """
  """
  use Guardian, otp_app: :alloy_ci

  alias AlloyCi.{Repo, User}

  def subject_for_token(%User{} = user, _claims), do: {:ok, "User:#{user.id}"}
  def subject_for_token(resource, _), do: {:error, "Unknown resource type #{resource}"}

  def resource_from_claims(%{"sub" => "User:" <> id}), do: {:ok, Repo.get(User, id)}
  def resource_from_claims(_), do: {:error, "Unknown resource type"}

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
