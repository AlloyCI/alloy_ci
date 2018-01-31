defmodule AlloyCi.Notifiers.Slack do
  @moduledoc """
  """
  import AlloyCi.Web.Router.Helpers

  def send_notification(notification) do
    HTTPoison.post(config()[:hook_url], build_payload(notification), [
      {"content-type", "application/json"}
    ])
  end

  ###################
  # Private functions
  ###################
  defp base_notification_text(notification) do
    "The pipeline with ID: #{notification.content["pipeline"]["id"]} for the branch *#{
      notification.content["pipeline"]["ref"] |> String.replace("refs/heads/", "")
    }*"
  end

  defp build_payload(notification) do
    payload = %{
      text: notification_text(notification),
      channel: config()[:channel],
      username: config()[:service_name]
    }

    Poison.encode!(payload)
  end

  defp commit_message(notification) do
    "*Commit message:* " <> notification.content["pipeline"]["commit"]["message"]
  end

  defp config do
    :alloy_ci
    |> Application.fetch_env!(__MODULE__)
    |> Map.new()
  end

  defp notification_text(%{notification_type: "pipeline_failed"} = notification) do
    base_notification_text(notification) <>
      " has failed. You can view the full trace log of the pipeline " <>
      "<#{pipeline_url(notification)}|here.>\n" <> commit_message(notification)
  end

  defp notification_text(%{notification_type: "pipeline_succeeded"} = notification) do
    base_notification_text(notification) <>
      " has finished correctly. You can view the full trace log of the pipeline " <>
      "<#{pipeline_url(notification)}|here.>\n" <> commit_message(notification)
  end

  defp pipeline_url(notification) do
    project_pipeline_url(
      AlloyCi.Web.Endpoint,
      :show,
      notification.project_id,
      notification.content["pipeline"]["id"]
    )
  end
end
