defmodule Metapede.Db.Schemas.Resource do
  alias Metapede.Db.Schemas.Topic
  alias Metapede.Db.Schemas.TimePeriod

  defstruct(
    res_id: nil,
    res_type: nil,
    info: nil
  )

  @res_types %{
    "time_period" => TimePeriod,
    "topic" => Topic,
    "event" => nil
  }

  def get_res_schema(resource), do: Map.get(@res_types, resource.res_type)

  def create_references(model) do
    updated_resources =
      model.resources
      |> Enum.map(fn res ->
        res
        |> pair_resource_schema
        |> save_resource
        |> save_reference
      end)

    model
    |> Map.replace(:resources, updated_resources)
  end

  defp pair_resource_schema(resource), do: {get_res_schema(resource), resource}

  defp save_resource({nil, resource}) do
    {nil,
     resource
     |> Map.update(:info, resource.info, fn info ->
       Topic.extract_topic(info)
     end)}
  end

  defp save_resource({schema, resource}), do: {schema.extract_and_ref(resource.info), resource}

  def save_reference({nil, resource}), do: resource

  def save_reference({id, resource}, ref_name \\ :res_id, drop_name \\ :info) do
    resource
    |> Map.put_new(ref_name, id)
    |> Map.drop([drop_name])
  end

  def load_all(resources), do: Enum.map(resources, &load(&1))
  def load(resource), do: get_res_schema(resource).load(resource.res_id)
end
