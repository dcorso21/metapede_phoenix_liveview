defmodule Metapede.Db.Schemas.TimePeriod do
  use Metapede.Db.GenCollection,
    collection_name: "time_periods",
    prefix: "tpd",
    has_topic: true

  alias Metapede.Db.Schemas.Topic

  defstruct(
    topic: nil,
    topic_id: nil,
    start_datetime: nil,
    end_datetime: nil,
    sub_time_period_ids: []
  )

  def validate(attr), do: attr

  def unload(time_period) do
    time_period
    |> Topic.unload_topic()
    |> Map.update("sub_time_periods", [], &unload_sub_time_periods/1)
    |> upsert()
    |> Map.get("_id")
  end

  def load(id, _resource, depth \\ 2) do
    tp = get_by_id(id)

    tp
    |> Map.put("topic", Topic.load(tp["topic_id"], tp))
    |> Map.update("sub_time_periods", [], &load_sub_periods(&1, depth))
  end

  defp unload_sub_time_periods(tps), do: Enum.map(tps, &unload/1)

  defp load_sub_periods(sub_time_periods, depth) when depth === 0, do: sub_time_periods
  defp load_sub_periods(sub_time_periods, depth),
    do: Enum.map(sub_time_periods, &load(&1, &1, depth - 1))
end
