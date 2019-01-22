defmodule AlloyCi.Notifiers.Email do
  @moduledoc false
  use Bamboo.Mailer, otp_app: :alloy_ci
  alias AlloyCi.{Emails, Notification}

  @spec send_notification(Notification.t()) :: Bamboo.Email.t()
  def send_notification(notification) do
    notification
    |> Emails.notification_email()
    |> __MODULE__.deliver_now()
  end

  @spec config() :: map()
  def config do
    :alloy_ci
    |> Application.fetch_env!(__MODULE__)
    |> Map.new()
  end
end

defmodule AlloyCi.Emails do
  @moduledoc false
  use Bamboo.Phoenix, view: AlloyCi.Web.EmailView
  import Bamboo.Email
  alias AlloyCi.{Notification, Notifiers.Email}

  @spec notification_email(Notification.t()) :: Bamboo.Email.t()
  def notification_email(notification) do
    notification
    |> prepare_notification_email()
    |> assign(:notification, notification)
    |> render("pipeline_status.html")
  end

  ###################
  # Private functions
  ###################
  defp base_email do
    new_email()
    |> from(Email.config()[:from_address])
    |> put_header("Reply-To", Email.config()[:reply_to_address])
    |> put_html_layout({AlloyCi.Web.LayoutView, "email_layout.html"})
  end

  defp prepare_notification_email(%{notification_type: "pipeline_failed"} = notification) do
    base_email()
    |> to(notification.user.email)
    |> subject("#{notification.project.name} |> Pipeline has failed!")
  end

  defp prepare_notification_email(%{notification_type: "pipeline_succeeded"} = notification) do
    base_email()
    |> to(notification.user.email)
    |> subject("#{notification.project.name} |> Pipeline completed successfully!")
  end
end
