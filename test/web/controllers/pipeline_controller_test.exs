# defmodule AlloyCi.Web.PipelineControllerTest do
#   use AlloyCi.Web.ConnCase
#
#   alias AlloyCi.Pipelines
#
#   @create_attrs %{before_sha: "some before_sha", commit_message: "some commit_message", committer_email: "some committer_email", duration: 42, finished_at: ~N[2010-04-17 14:00:00.000000], project_id: 42, ref: "some ref", sha: "some sha", started_at: ~N[2010-04-17 14:00:00.000000], status: "some status"}
#   @update_attrs %{before_sha: "some updated before_sha", commit_message: "some updated commit_message", committer_email: "some updated committer_email", duration: 43, finished_at: ~N[2011-05-18 15:01:01.000000], project_id: 43, ref: "some updated ref", sha: "some updated sha", started_at: ~N[2011-05-18 15:01:01.000000], status: "some updated status"}
#   @invalid_attrs %{before_sha: nil, commit_message: nil, committer_email: nil, duration: nil, finished_at: nil, project_id: nil, ref: nil, sha: nil, started_at: nil, status: nil}
#
#   def fixture(:pipeline) do
#     {:ok, pipeline} = Pipelines.create_pipeline(@create_attrs)
#     pipeline
#   end
#
#   test "lists all entries on index", %{conn: conn} do
#     conn = get conn, pipeline_path(conn, :index)
#     assert html_response(conn, 200) =~ "Listing Pipelines"
#   end
#
#   test "renders form for new pipelines", %{conn: conn} do
#     conn = get conn, pipeline_path(conn, :new)
#     assert html_response(conn, 200) =~ "New Pipeline"
#   end
#
#   test "creates pipeline and redirects to show when data is valid", %{conn: conn} do
#     conn = post conn, pipeline_path(conn, :create), pipeline: @create_attrs
#
#     assert %{id: id} = redirected_params(conn)
#     assert redirected_to(conn) == pipeline_path(conn, :show, id)
#
#     conn = get conn, pipeline_path(conn, :show, id)
#     assert html_response(conn, 200) =~ "Show Pipeline"
#   end
#
#   test "does not create pipeline and renders errors when data is invalid", %{conn: conn} do
#     conn = post conn, pipeline_path(conn, :create), pipeline: @invalid_attrs
#     assert html_response(conn, 200) =~ "New Pipeline"
#   end
#
#   test "renders form for editing chosen pipeline", %{conn: conn} do
#     pipeline = fixture(:pipeline)
#     conn = get conn, pipeline_path(conn, :edit, pipeline)
#     assert html_response(conn, 200) =~ "Edit Pipeline"
#   end
#
#   test "updates chosen pipeline and redirects when data is valid", %{conn: conn} do
#     pipeline = fixture(:pipeline)
#     conn = put conn, pipeline_path(conn, :update, pipeline), pipeline: @update_attrs
#     assert redirected_to(conn) == pipeline_path(conn, :show, pipeline)
#
#     conn = get conn, pipeline_path(conn, :show, pipeline)
#     assert html_response(conn, 200) =~ "some updated before_sha"
#   end
#
#   test "does not update chosen pipeline and renders errors when data is invalid", %{conn: conn} do
#     pipeline = fixture(:pipeline)
#     conn = put conn, pipeline_path(conn, :update, pipeline), pipeline: @invalid_attrs
#     assert html_response(conn, 200) =~ "Edit Pipeline"
#   end
#
#   test "deletes chosen pipeline", %{conn: conn} do
#     pipeline = fixture(:pipeline)
#     conn = delete conn, pipeline_path(conn, :delete, pipeline)
#     assert redirected_to(conn) == pipeline_path(conn, :index)
#     assert_error_sent 404, fn ->
#       get conn, pipeline_path(conn, :show, pipeline)
#     end
#   end
# end
