defmodule AlloyCi.Web.EmailView do
  use AlloyCi.Web, :view
  import AlloyCi.Web.NotificationView, only: [notification_text: 1]
end
