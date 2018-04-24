defmodule AlloyCi.Web.NotificationView do
  use AlloyCi.Web, :view
  import AlloyCi.Web.Router.Helpers
  import AlloyCi.Builds, only: [clean_ref: 1]
  use Phoenix.HTML

  def notification_text(%{notification_type: "pipeline_failed"} = notification) do
    [
      content_tag :p do
        [
          base_notification_text(notification),
          " has failed. You can view the full trace log of the pipeline ",
          link_to_pipeline(notification)
        ]
      end,
      commit_message(notification)
    ]
  end

  def notification_text(%{notification_type: "pipeline_succeeded"} = notification) do
    [
      content_tag :p do
        [
          base_notification_text(notification),
          " has finished correctly. You can view the full trace log of the pipeline ",
          link_to_pipeline(notification)
        ]
      end,
      commit_message(notification)
    ]
  end

  ###################
  # Private functions
  ###################
  defp base_notification_text(notification) do
    [
      "The pipeline with ID: #{notification.content["pipeline"]["id"]} for ",
      content_tag(:b, notification.content["pipeline"]["ref"] |> clean_ref())
    ]
  end

  defp commit_message(notification) do
    content_tag :p do
      [
        content_tag(:b, "Commit message: "),
        notification.content["pipeline"]["commit"]["message"]
      ]
    end
  end

  defp link_to_pipeline(notification) do
    link(
      "here.",
      to:
        project_pipeline_url(
          AlloyCi.Web.Endpoint,
          :show,
          notification.project_id,
          notification.content["pipeline"]["id"]
        )
    )
  end
end
