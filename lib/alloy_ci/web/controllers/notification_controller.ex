defmodule AlloyCi.Web.NotificationController do
  use AlloyCi.Web, :controller
  alias AlloyCi.Notifications
  plug(EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access")

  def delete(conn, %{"id" => id}, current_user, _) do
    with {1, _} <- Notifications.delete(id, current_user) do
      conn
      |> put_flash(:info, "Notification was deleted")
      |> redirect(to: notification_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "Notification not found")
        |> redirect(to: notification_path(conn, :index))
    end
  end

  def index(conn, _, current_user, _) do
    unread = Notifications.for_user(current_user)
    acknowledged = Notifications.for_user(current_user, true)

    render(
      conn,
      "index.html",
      unread: unread,
      acknowledged: acknowledged,
      current_user: current_user
    )
  end

  def update(conn, %{"id" => id}, current_user, _) do
    with {:ok, _} <- Notifications.acknowledge!(id, current_user) do
      conn
      |> put_flash(:info, "Notification was acknowledged")
      |> redirect(to: notification_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "Notification not found")
        |> redirect(to: notification_path(conn, :index))
    end
  end
end
