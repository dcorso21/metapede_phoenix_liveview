defmodule Metapede.Timeline.TimePeriod do
  use Ecto.Schema
  alias Metapede.Collection.Topic
  alias Metapede.Timeline.{Event, TimePeriod}
  alias Metapede.Relations.{TimePeriodAndEventRelations, TimePeriodRelations}
  @accepted_fields [:start_datetime, :end_datetime]

  schema "time_periods" do
    belongs_to :topic, Topic
    field :start_datetime, :string
    field :end_datetime, :string

    many_to_many(
      :events,
      Event,
      join_through: TimePeriodAndEventRelations,
      on_delete: :delete_all
    )

    many_to_many(
      :sub_time_periods,
      TimePeriod,
      join_through: TimePeriodRelations,
      join_keys: [parent_time_period_id: :id, child_time_period_id: :id],
      on_delete: :delete_all
    )

    many_to_many(
      :parent_time_periods,
      TimePeriod,
      join_through: TimePeriodRelations,
      join_keys: [child_time_period_id: :id, parent_time_period_id: :id],
      on_delete: :delete_all
    )

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> Ecto.Changeset.cast(params, @accepted_fields)
    # |> Ecto.Changeset.validate_required([:])
    |> Ecto.Changeset.foreign_key_constraint(:events)
    |> Ecto.Changeset.foreign_key_constraint(:parent_time_periods)
    |> Ecto.Changeset.foreign_key_constraint(:sub_time_periods)
  end
end