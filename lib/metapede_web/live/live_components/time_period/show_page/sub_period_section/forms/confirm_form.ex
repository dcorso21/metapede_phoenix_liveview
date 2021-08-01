defmodule MetapedeWeb.LiveComponents.TimePeriod.ConfirmForm do
  use MetapedeWeb, :live_component
  alias Metapede.CommonSearchFuncs
  alias Metapede.TimelineContext.TimePeriodContext
  alias MetapedeWeb.Controllers.Transforms.DatetimeOps

  def render(assigns) do
    ~L"""
    <%= if @new_topic != nil do %>
    <div class="confirm_box">
      <div class="left_form">
          <h1>Confirm the period Creation Please</h1>
          <div>
              Title: <%= @new_topic.title %>
          </div>
          <div>
              Description: <%= @new_topic.description %>
          </div>
          <%= form_for Metapede.Timeline.TimePeriodSchema.TimePeriod, "#",
            id: "time_period_form",
            autocomplete: "off",
            phx_target: @myself,
            phx_submit: "submit_confirmed" %>

            <div class="date_options">
              <%= live_component @socket,
                MetapedeWeb.LiveComponents.TimePeriod.DateSelectorComponent,
                title: "Start Date",
                prefix: "sdt"
              %>

              <%= live_component @socket,
                MetapedeWeb.LiveComponents.TimePeriod.DateSelectorComponent,
                title: "End Date",
                prefix: "edt"
              %>

            </div>

          <%= submit "Save", phx_disable_with: "Saving..." %>
          </form>
      </div>

      <div class="right_page">
        <%= live_component @socket,
          MetapedeWeb.LiveComponents.WikiContent,
          page_id: @new_topic.page_id,
          id: @new_topic.title <> "_page"
        %>
      </div>

    </div>
    <% end %>
    """
  end

  def handle_event("submit_confirmed", params, socket) do
    new_period = %{
      start_datetime: DatetimeOps.make_datetimes(params, "sdt"),
      end_datetime: DatetimeOps.make_datetimes(params, "edt")
    }

    case TimePeriodContext.create_time_period(new_period) do
      {:ok, saved_period} ->
        loaded = Metapede.Repo.preload(saved_period, [:topic])

        created_period =
          Metapede.CommonSearchFuncs.add_association(
            socket.assigns.new_topic,
            loaded,
            :topic,
            fn el -> el end
          )

        if socket.assigns.parent_time_period != "nil", do: add_subtopic(created_period, socket)

        IO.puts("Return To")
        IO.inspect(socket.assigns.return_to)


        {:noreply,
         socket
         |> assign(refresh_sub_periods: true)
         |> put_flash(:info, "New Period Added: #{created_period.topic.title}")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, message} ->
        IO.inspect(message)

        {:noreply,
         socket
         |> put_flash(:error, "An Error Occurred")
         |> push_redirect(to: Routes.time_period_index_path(socket, :main))}

      resp ->
        IO.inspect(resp)
    end
  end

  def adding(topic, socket) do
    topic.time_period
    |> block_self_reference(socket.assigns.parent_time_period.id)
    |> add_to_subtopics(socket)

    {
      :noreply,
      socket
      |> put_flash(:info, "Sub Time Period Added: #{topic.title}")
      |> push_redirect(
        to: Routes.time_period_show_path(socket, :main, socket.assigns.parent_time_period)
      )
    }
  end

  def block_self_reference(new_period, current_id) do
    if new_period.id == current_id do
      {:self, nil}
    else
      {:not_self, new_period}
    end
  end

  def add_to_subtopics({:self, _time_period}, _socket), do: nil

  def add_to_subtopics({:not_self, time_period}, socket) do
    CommonSearchFuncs.add_association(
      time_period,
      socket.assigns.parent_time_period,
      :sub_time_periods,
      fn el ->
        [el | socket.assigns.parent_time_period.sub_time_periods]
      end
    )
  end

  def add_subtopic(sub_period, socket) do
    par_period = socket.assigns.parent_time_period

    Metapede.CommonSearchFuncs.add_association(
      sub_period,
      par_period,
      :sub_time_periods,
      fn el -> [el | par_period.sub_time_periods] end
    )
  end
end
