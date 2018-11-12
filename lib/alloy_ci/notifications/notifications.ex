defmodule AlloyCi.Notifications do
  @moduledoc """
  The boundary for the Notifications system.
  """
  import Ecto.Query, warn: false
  alias AlloyCi.{Notification, Notifier, Pipeline, Repo, User}

  @spec acknowledge!(any(), User.t()) :: Notification.t()
  def acknowledge!(id, user) do
    with %Notification{} = notification <- get(id, user) do
      notification
      |> Notification.changeset(%{acknowledged: true})
      |> Repo.update()
    end
  end

  @spec acknowledge_all(User.t()) :: any()
  def acknowledge_all(user) do
    query =
      from(
        n in Notification,
        where: n.user_id == ^user.id and n.acknowledged == false,
        update: [set: [acknowledged: true]]
      )

    Repo.update_all(query, [])
  end

  @spec count_for_user(User.t()) :: integer()
  def count_for_user(user) do
    query =
      from(
        n in Notification,
        where: n.user_id == ^user.id and n.acknowledged == false,
        select: count(n.id)
      )

    Repo.one(query)
  end

  @spec delete(any(), User.t()) :: any()
  def delete(id, user) do
    Notification
    |> where(id: ^id, user_id: ^user.id)
    |> Repo.delete_all()
  end

  @spec delete_all(User.t()) :: any()
  def delete_all(user) do
    Notification
    |> where(user_id: ^user.id, acknowledged: ^true)
    |> Repo.delete_all()
  end

  @spec for_user(User.t(), any()) :: [Notification.t()]
  def for_user(user, acknowledged \\ false) do
    Notification
    |> where(user_id: ^user.id, acknowledged: ^acknowledged)
    |> order_by(desc: :inserted_at)
    |> limit(20)
    |> preload(:project)
    |> Repo.all()
  end

  @spec get(any()) :: Notification.t()
  def get(id), do: Notification |> Repo.get(id)

  @spec get(any(), User.t()) :: Notification.t()
  def get(id, user) do
    Notification
    |> where(user_id: ^user.id)
    |> Repo.get(id)
  end

  @spec get_with_project_and_user(any()) :: Notification.t()
  def get_with_project_and_user(id) do
    Notification
    |> Repo.get(id)
    |> Repo.preload([:project, :user])
  end

  @spec send(map(), Pipeline.t(), any()) ::
          :ok
          | {:error, any()}
          | {:ok, HTTPoison.Response.t()}
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
    with %Notification{} = notification <- do_create(user, project, type, content) do
      Notifier.notify!(notification)
    end
  end

  defp do_create(user, project, type, content) do
    params = %{
      user_id: user.id,
      project_id: project.id,
      notification_type: type,
      content: content
    }

    %Notification{}
    |> Notification.changeset(params)
    |> Repo.insert!()
    |> Repo.preload([:project, :user])
  end

  defp user_for_pipeline(pipeline) do
    result =
      User
      |> where(email: ^pipeline.commit["pusher_email"])
      |> limit(1)
      |> Repo.one()

    case result do
      nil ->
        query =
          from(
            u in User,
            join: p in "project_permissions",
            on: p.user_id == u.id,
            where: p.project_id == ^pipeline.project_id,
            limit: 1,
            select: u
          )

        Repo.one(query)

      %User{} = user ->
        user
    end
  end
end
