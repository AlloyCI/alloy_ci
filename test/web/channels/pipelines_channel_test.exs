defmodule AlloyCi.Web.PipelinesChannelTest do
  use AlloyCi.Web.ChannelCase
  import AlloyCi.Factory

  alias AlloyCi.Web.PipelinesChannel

  setup do
    pipeline = insert(:pipeline)

    user =
      insert(:user, project_permissions: [build(:project_permission, project: pipeline.project)])

    {:ok, _, socket} =
      "user_id"
      |> socket(%{user_id: user.id})
      |> subscribe_and_join(PipelinesChannel, "pipeline:#{pipeline.id}")

    {:ok, socket: socket, pipeline: pipeline}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply(ref, :ok, %{"hello" => "there"})
  end

  test "shout broadcasts to pipelines:lobby", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast("shout", %{"hello" => "all"})
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push("broadcast", %{"some" => "data"})
  end

  test "update_status sends the correct data", %{pipeline: pipeline} do
    PipelinesChannel.update_status(pipeline)
    assert_push("update_status", %{content: <<_div::binary-size(9), "pipeline-", _rest::binary>>})
  end
end
