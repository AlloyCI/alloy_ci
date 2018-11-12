defmodule AlloyCi.Web.SharedView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Notification, Notifications, User}
  import AlloyCi.Web.RunnerView, only: [global: 1, platform_icon: 1]

  @spec notification_badge(User.t()) :: <<>> | {:safe, [...]}
  def notification_badge(user) do
    case Notifications.count_for_user(user) do
      0 ->
        ""

      count ->
        content_tag :span, class: "badge badge-pill badge-danger" do
          count
        end
    end
  end

  @spec user_notifications(User.t()) :: [Notification.t()]
  def user_notifications(user) do
    Notifications.for_user(user)
  end
end
