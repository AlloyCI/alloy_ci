defmodule AlloyCi.Web.BuildsChannelTest do
  use AlloyCi.Web.ChannelCase
  import AlloyCi.Factory

  alias AlloyCi.Web.BuildsChannel

  setup do
    build = insert(:full_build)

    user =
      insert(:user, project_permissions: [build(:project_permission, project: build.project)])

    {:ok, _, socket} =
      "user_id"
      |> socket(%{user_id: user.id})
      |> subscribe_and_join(BuildsChannel, "builds:#{build.id}")

    {:ok, socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply(ref, :ok, %{"hello" => "there"})
  end

  test "shout broadcasts to builds:lobby", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast("shout", %{"hello" => "all"})
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push("broadcast", %{"some" => "data"})
  end
end
