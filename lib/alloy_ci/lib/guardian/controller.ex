defmodule AlloyCi.Guardian.Controller do
  @moduledoc false
  defmacro __using__(opts \\ []) do
    quote do
      import Guardian.Plug

      def action(conn, _opts) do
        user = AlloyCi.Guardian.Plug.current_resource(conn, unquote(opts))

        if user do
          Sentry.Context.set_user_context(%{id: user.id, email: user.email})
        end

        apply(__MODULE__, action_name(conn), [
          conn,
          conn.params,
          user,
          AlloyCi.Guardian.Plug.current_claims(conn, unquote(opts))
        ])
      end
    end
  end
end
