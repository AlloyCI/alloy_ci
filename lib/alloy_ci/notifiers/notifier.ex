defmodule AlloyCi.Notifier do
  @moduledoc """
  """
  alias AlloyCi.{Notifiers, Notifications}
  require Logger

  def notify!(notification_id) do
    notification_id
    |> Notifications.get_with_project_and_user()
    |> send_notifications(config())
  end

  ###################
  # Private functions
  ###################
  defp config do
    :alloy_ci
    |> Application.fetch_env!(__MODULE__)
    |> Map.new()
  end

  defp send_notifications(notification, %{email: "true", slack: "true"}) do
    send_email(notification)
    send_slack(notification)
  end

  defp send_notifications(notification, %{email: "true", slack: "false"}) do
    send_email(notification)
  end

  defp send_notifications(notification, %{email: "false", slack: "true"}) do
    send_slack(notification)
  end

  defp send_notifications(_, _) do
    Logger.info("No notifiers have been configured. Skipping...")
  end

  defp send_email(notification) do
    Notifiers.Email.send_notification(notification)
  end

  defp send_slack(notification) do
    Notifiers.Slack.send_notification(notification)
  end
end
