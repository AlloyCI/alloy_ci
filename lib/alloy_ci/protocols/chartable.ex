defprotocol Chartable do
  def builds_chart(subject)
  def projects_chart(subject)
end

defimpl Chartable, for: AlloyCi.Project do
  alias AlloyCi.Repo
  import Ecto.Query

  def builds_chart(project) do
    query = from b in "builds",
            where: b.project_id == ^project.id and b.status in ~w(failed success) and b.updated_at > ^Chart.interval,
            group_by: [b.status, fragment("date_trunc('week', ?)", b.updated_at)],
            select: {fragment("date_trunc('week', ?)", b.updated_at), b.status, count("*")}
    builds = Repo.all(query)

    Chart.line_chart(builds)
  end

  def projects_chart(_), do: nil
end

defimpl Chartable, for: AlloyCi.Runner do
  alias AlloyCi.Repo
  import Ecto.Query

  def builds_chart(runner) do
    query = from b in "builds",
            where: b.runner_id == ^runner.id and b.status in ~w(failed success) and b.updated_at > ^Chart.interval,
            group_by: [b.status, fragment("date_trunc('week', ?)", b.updated_at)],
            select: {fragment("date_trunc('week', ?)", b.updated_at), b.status, count("*")}
    builds = Repo.all(query)

    Chart.line_chart(builds)
  end

  def projects_chart(runner) do
    query = from b in "builds",
            where: b.runner_id == ^runner.id and b.status in ~w(failed success) and b.updated_at > ^Chart.interval,
            group_by: [b.project_id],
            select: {b.project_id, count("*")}
    builds = Repo.all(query)

    Chart.doughnut_chart(builds)
  end
end

defmodule Chart do
  @moduledoc """
  """
  alias AlloyCi.Projects

  def doughnut_chart(builds) do
    {_ , result} =
      Enum.map_reduce(builds, %{}, fn({project, count}, acc) ->
        {nil, Map.merge(acc, %{project => count}, fn(_, v1, v2) -> v1 + v2 end)}
      end)

    %{
      labels: result |> Map.keys |> Enum.map(fn project_id -> Projects.get(project_id).name end),
      datasets: [
        %{
          data: result |> Map.values,
          backgroundColor: result |> Enum.map(fn _ -> "rgb(#{:rand.uniform(255)}, #{:rand.uniform(255)}, #{:rand.uniform(255)})" end),
          label: "Projects"
        }
      ]
    }
  end

  def line_chart(builds) do
    {_, result} =
      Enum.map_reduce(builds, %{}, fn({day, status, count}, acc) ->
        {
          nil,
          Map.merge(acc, %{"#{day |> Timex.to_date}" => %{status => count}}, fn(_, v1, v2) ->
            Map.merge(v1, v2)
          end)
        }
      end)

    %{
      labels: result |> Map.keys,
      datasets: [
        %{
          label: "Total builds",
          borderColor: "rgb(2,117,216)",
          backgroundColor: "rgb(2,117,216)",
          data: result |> Map.values |> Enum.map(fn x -> Enum.reduce(x, 0, fn {_, v}, acc -> v + acc end) end),
          fill: false
        },
        %{
          label: "Successful builds",
          borderColor: "rgb(77,189,116)",
          backgroundColor: "rgb(77,189,116)",
          data: result |> Map.values |> Enum.map(fn x -> x["success"] || 0 end),
          fill: false
        },
        %{
          label: "Failed builds",
          borderColor: "rgb(248,108,107)",
          backgroundColor: "rgb(248,108,107)",
          data: result |> Map.values |> Enum.map(fn x -> x["failed"] || 0 end),
          fill: false
        }
      ]
    }
  end

  def interval, do: Timex.now |> Timex.shift(months: -3)
end
