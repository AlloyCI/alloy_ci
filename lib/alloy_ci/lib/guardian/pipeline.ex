defmodule AlloyCi.Guardian.Pipeline do
  @claims %{typ: "access"}

  use Guardian.Plug.Pipeline,
    otp_app: :alloy_ci,
    module: AlloyCi.Guardian,
    error_handler: AlloyCi.Web.AuthController

  plug(Guardian.Plug.VerifySession, claims: @claims)
  plug(Guardian.Plug.LoadResource, ensure: true)
end

defmodule AlloyCi.Guardian.AdminPipeline do
  @claims %{typ: "access"}

  use Guardian.Plug.Pipeline,
    otp_app: :alloy_ci,
    module: AlloyCi.Guardian,
    error_handler: AlloyCi.Web.Admin.UserController

  plug(Guardian.Plug.VerifySession, claims: @claims, key: :admin)
  plug(Guardian.Plug.LoadResource, key: :admin)
end
