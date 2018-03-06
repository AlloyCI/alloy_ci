defmodule AlloyCi.Guardian.Pipeline do
  @moduledoc """
  Guardian Pipeline needed to validate and load user resource
  """
  @claims %{typ: "access"}

  use Guardian.Plug.Pipeline,
    otp_app: :alloy_ci,
    module: AlloyCi.Guardian,
    error_handler: AlloyCi.Web.AuthController

  plug(Guardian.Plug.VerifySession, claims: @claims)
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end

defmodule AlloyCi.Guardian.AdminPipeline do
  @moduledoc """
  Guardian Pipeline needed to validate and load admin user resource
  """
  @claims %{typ: "access"}

  use Guardian.Plug.Pipeline,
    otp_app: :alloy_ci,
    module: AlloyCi.Guardian,
    error_handler: AlloyCi.Web.Admin.UserController

  plug(Guardian.Plug.VerifySession, claims: @claims, key: :admin)
  plug(Guardian.Plug.LoadResource, allow_blank: true, key: :admin)
end
