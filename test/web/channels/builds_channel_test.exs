defmodule AlloyCi.Web.BuildsChannelTest do
  use AlloyCi.Web.ChannelCase
  import AlloyCi.Factory

  alias AlloyCi.Web.{BuildsChannel, UserSocket}

  setup do
    build = insert(:full_build)

    user =
      insert(:user, project_permissions: [build(:project_permission, project: build.project)])

    {:ok, _, socket} =
      socket(UserSocket, "user_id", %{user_id: user.id})
      |> subscribe_and_join(BuildsChannel, "build:#{build.id}")

    {:ok, socket: socket, build: build}
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

  test "update_status sends the correct data", %{build: build} do
    BuildsChannel.update_status(build)
    assert_push("update_status", %{content: <<_div::binary-size(9), "build-", _rest::binary>>})
  end
end
