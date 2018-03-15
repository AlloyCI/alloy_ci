defmodule AlloyCi.Web.SharedView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Notifications}

  def global(true), do: icon("globe")
  def global(false), do: icon("plug")

  def notification_count(user) do
    Notifications.count_for_user(user)
  end

  def user_notifications(user) do
    Notifications.for_user(user)
  end

  def platform_icon("darwin"), do: icon("apple")
  def platform_icon("windows"), do: icon("windows")
  def platform_icon("linux"), do: icon("linux")
end
