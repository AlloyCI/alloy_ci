defmodule AlloyCi.ViewHelpers do
  def active_on_current(%{request_path: path}, path), do: "active"
  def active_on_current(_, _), do: ""

  def admin_logged_in?(conn), do: Guardian.Plug.authenticated?(conn, :admin)
  def admin_user(conn), do: Guardian.Plug.current_resource(conn, :admin)

  def logged_in?(conn), do: Guardian.Plug.authenticated?(conn)
  def current_user(conn), do: Guardian.Plug.current_resource(conn)

  def icon(name) do
    {:safe, "<i class='fa fa-#{name}'></i>"}
  end

  def icon(name, classes) do
    {:safe, "<i class='fa fa-#{name} #{classes}'></i>"}
  end
end
