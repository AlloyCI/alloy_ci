defprotocol Chartable do
  @doc """
  Prepares an array of 3 element tuples, which is then turned into a map containing the
  data needed to draw a chart detailing the build statuses per week.

  The tuple is created by grouping the builds by the week in which they were created and
  their status. This allows us to select the `updated_at` and the `status` fields, and
  count them.

  Example intermediate result:

      [{{{2017, 11, 27}, {0, 0, 0, 0}}, "success", 1}]
  """
  def builds_chart(subject)

  @doc """
  Prepares an array of tuples, which is then turned into a map containing the data needed
  to draw a chart detailing how many builds have run for a specific project and runner.

  The tuple is created by grouping the builds by their project and returning the `project_id`
  and count.

  Example intermediate result:

      [{4, 15}]
  """
  def projects_chart(subject)
end

defimpl Chartable, for: AlloyCi.Project do
  alias AlloyCi.Repo
  import Ecto.Query

  def builds_chart(project) do
    from(
      b in "builds",
      where:
        b.project_id == ^project.id and b.status in ~w(failed success) and
          b.updated_at > ^Chart.interval(),
      group_by: [b.status, fragment("date_trunc('week', ?)", b.updated_at)],
      select: {fragment("date_trunc('week', ?)", b.updated_at), b.status, count("*")}
    )
    |> Repo.all()
    |> Chart.line_chart()
  end

  def projects_chart(_), do: nil
end

defimpl Chartable, for: AlloyCi.Runner do
  alias AlloyCi.Repo
  import Ecto.Query

  def builds_chart(runner) do
    from(
      b in "builds",
      where:
        b.runner_id == ^runner.id and b.status in ~w(failed success) and
          b.updated_at > ^Chart.interval(),
      group_by: [b.status, fragment("date_trunc('week', ?)", b.updated_at)],
      select: {fragment("date_trunc('week', ?)", b.updated_at), b.status, count("*")}
    )
    |> Repo.all()
    |> Chart.line_chart()
  end

  def projects_chart(runner) do
    from(
      b in "builds",
      where:
        b.runner_id == ^runner.id and b.status in ~w(failed success) and
          b.updated_at > ^Chart.interval(),
      group_by: [b.project_id],
      select: {b.project_id, count("*")}
    )
    |> Repo.all()
    |> Chart.doughnut_chart()
  end
end

defmodule Chart do
  @moduledoc """
  Provides access to the functions that actually build the necessary data for
  Chart.js to do its thing.

  Exposes 2 functions: `Chart.doughnut_chart/1` and `Chart.line_chart/1`
  """
  alias AlloyCi.Projects

  @doc """
  Prepares a map with the data necessary to create a doughnut chart. Since it groups
  the number of builds by their project, it returns a random color for each project.

  Used only for runners.
  """
  def doughnut_chart(builds) do
    {_, result} =
      Enum.map_reduce(builds, %{}, fn {project, count}, acc ->
        {nil, Map.merge(acc, %{project => count}, fn _, v1, v2 -> v1 + v2 end)}
      end)

    %{
      labels:
        result |> Map.keys() |> Enum.map(fn project_id -> Projects.get(project_id).name end),
      datasets: [
        %{
          data: result |> Map.values(),
          backgroundColor:
            result
            |> Enum.map(fn _ ->
              "rgb(#{:rand.uniform(255)}, #{:rand.uniform(255)}, #{:rand.uniform(255)})"
            end),
          label: "Projects"
        }
      ]
    }
  end

  @doc """
  Prepares a map with the data necessary to create a line chart. It groups the builds
  by the week in which they were updated, and creates a point based on their status.
  It thens plots a line between the points.

  Used for projects.
  """
  def line_chart(builds) do
    {_, result} =
      Enum.map_reduce(builds, %{}, fn {day, status, count}, acc ->
        {
          nil,
          Map.merge(acc, %{"#{day |> Timex.to_date()}" => %{status => count}}, fn _, v1, v2 ->
            Map.merge(v1, v2)
          end)
        }
      end)

    %{
      labels: result |> Map.keys(),
      datasets: [
        %{
          label: "Total builds",
          borderColor: "rgb(2,117,216)",
          backgroundColor: "rgb(2,117,216)",
          data:
            result
            |> Map.values()
            |> Enum.map(fn x -> Enum.reduce(x, 0, fn {_, v}, acc -> v + acc end) end),
          fill: false
        },
        %{
          label: "Successful builds",
          borderColor: "rgb(77,189,116)",
          backgroundColor: "rgb(77,189,116)",
          data: result |> Map.values() |> Enum.map(fn x -> x["success"] || 0 end),
          fill: false
        },
        %{
          label: "Failed builds",
          borderColor: "rgb(248,108,107)",
          backgroundColor: "rgb(248,108,107)",
          data: result |> Map.values() |> Enum.map(fn x -> x["failed"] || 0 end),
          fill: false
        }
      ]
    }
  end

  def interval, do: Timex.now() |> Timex.shift(months: -3)
end
