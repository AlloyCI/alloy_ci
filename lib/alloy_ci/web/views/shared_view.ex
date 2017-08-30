defmodule AlloyCi.Web.SharedView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Notifications}

  def notification_count(user) do
    Notifications.count_for_user(user)
  end

  def user_notifications(user) do
    Notifications.for_user(user)
  end
end
