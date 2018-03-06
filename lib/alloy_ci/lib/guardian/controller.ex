defmodule AlloyCi.Guardian.Controller do
  @moduledoc false
  defmacro __using__(opts \\ []) do
    quote do
      import Guardian.Plug

      def action(conn, _opts) do
        apply(__MODULE__, action_name(conn), [
          conn,
          conn.params,
          AlloyCi.Guardian.Plug.current_resource(conn, unquote(opts)),
          AlloyCi.Guardian.Plug.current_claims(conn, unquote(opts))
        ])
      end
    end
  end
end
