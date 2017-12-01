defmodule AlloyCi.Notifications do
  @moduledoc """
  """
  import Ecto.Query, warn: false
  alias AlloyCi.{Notification, Notifier, Repo, User}

  def aknowledge!(id, user) do
    with %Notification{} = notification <- get(id, user) do
      notification
      |> Notification.changeset(%{acknowledged: true})
      |> Repo.update
    end
  end

  def count_for_user(user) do
    query = from n in "notifications",
            where: n.user_id == ^user.id and n.acknowledged == false,
            select: count(n.id)
    Repo.one(query)
  end

  def delete(id, user) do
    Notification
    |> where([id: ^id, user_id: ^user.id])
    |> Repo.delete_all
  end

  def for_user(user, acknowledged \\ false) do
    Notification
    |> where([user_id: ^user.id, acknowledged: ^acknowledged])
    |> order_by(desc: :inserted_at)
    |> limit(20)
    |> Repo.all
    |> Repo.preload(:project)
  end

  def get(id) do
    Notification
    |> Repo.get(id)
  end

  def get(id, user) do
    Notification
    |> where([id: ^id, user_id: ^user.id])
    |> limit(1)
    |> Repo.one
  end

  def get_with_project_and_user(id) do
    Notification
    |> Repo.get(id)
    |> Repo.preload([:project, :user])
  end

  def send(pipeline, project, type) do
    pipeline = Map.drop(pipeline, [:__meta__, :__struct__, :builds, :project])

    pipeline
    |> user_for_pipeline()
    |> create(project, type, %{pipeline: pipeline})
  end

  ###################
  # Private functions
  ###################
  defp create(user, project, type, content) do
    with {:ok, notification} <- do_create(user, project, type, content) do
      Notifier.notify!(notification.id)
    end
  end

  defp do_create(user, project, type, content) do
    params = %{user_id: user.id, project_id: project.id, notification_type: type, content: content}

    %Notification{}
    |> Notification.changeset(params)
    |> Repo.insert
  end

  defp user_for_pipeline(pipeline) do
    result =
      User
      |> where(email: ^pipeline.commit["pusher_email"])
      |> limit(1)
      |> Repo.one

    case result do
      nil ->
        query = from u in User,
                join: p in "project_permissions", on: p.user_id == u.id,
                where: p.project_id == ^pipeline.project_id, limit: 1,
                select: u
        Repo.one(query)

      %User{} = user -> user
    end
  end
end
