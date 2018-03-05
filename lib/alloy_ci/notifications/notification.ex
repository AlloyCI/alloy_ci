defmodule AlloyCi.Notification do
  @moduledoc """
  """
  use AlloyCi.Web, :schema

  schema "notifications" do
    field(:acknowledged, :boolean, default: false)
    field(:content, :map)
    field(:notification_type, :string, default: "pipeline_failed")

    belongs_to(:project, AlloyCi.Project)
    belongs_to(:user, AlloyCi.User)

    timestamps()
  end

  @required_filed ~w(acknowledged content notification_type project_id user_id)a

  @doc false
  def changeset(notification, attrs \\ %{}) do
    notification
    |> cast(attrs, @required_filed)
    |> validate_required(@required_filed)
  end
end
