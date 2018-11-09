defmodule AlloyCi.Repo do
  use Ecto.Repo, otp_app: :alloy_ci, adapter: Ecto.Adapters.Postgres
  use Kerosene, per_page: 10
end
