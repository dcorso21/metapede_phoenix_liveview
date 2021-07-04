defmodule MetapedeWeb.TimePeriodLive.Show do
  use MetapedeWeb, :live_view
  alias Metapede.CommonSearchFuncs
  alias Metapede.TimelineContext.TimePeriodContext

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(new_topic: nil)
     |> assign(breadcrumbs: [])}
  end

  def handle_params(params, _url, socket) do
    tp = TimePeriodContext.get_time_period!(params["id"])
    IO.puts("Handle Params")
    IO.inspect(tp)

    new_topic =
      if(params["new_topic_id"], do: Metapede.Collection.get_topic!(params["new_topic_id"]), else: nil)

    {:noreply,
     socket
     |> assign(time_period: tp)
     |> assign(new_topic: new_topic)}
  end

  def handle_event("new_sub_time_period", %{"topic" => topic}, socket) do
    topic
    |> CommonSearchFuncs.decode_and_format_topic()
    |> CommonSearchFuncs.create_if_new()
    |> CommonSearchFuncs.check_for_existing_time_period()
    |> custom_redirect(socket)
  end

  def handle_event("confirmed_period2", params, socket) do
    new_period = %{
      start_datetime: make_datetimes(params, "sdt"),
      end_datetime: make_datetimes(params, "edt"),
    }

    case TimePeriodContext.create_time_period(new_period) do
      {:ok, saved_period} ->
        loaded = Metapede.Repo.preload(saved_period, [:topic])

        resp =
          Metapede.CommonSearchFuncs.add_association(
            socket.assigns.new_topic,
            loaded,
            :topic,
            fn el -> el end
          )

        add_subtopic(resp, socket)

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

  def handle_event("update_breadcrumbs", %{"breadcrumbs" => crumbs}, socket) do
    nc = crumbs |> Poison.decode!()
    tp = socket.assigns.time_period
    cp = [%{"name" => tp.topic.title, "id" => tp.id}]
    up = socket.assigns.breadcrumbs ++ cp ++ nc

    {:noreply,
     socket
     |> assign(breadcrumbs: up)}
  end

  def handle_event("reset_breadcrumbs" <> index, _, socket) do
    updated_breadcrumbs =
      socket.assigns.breadcrumbs
      |> Enum.take(String.to_integer(index))

    {:noreply, socket |> assign(breadcrumbs: updated_breadcrumbs)}
  end

  def add_subtopic(sub_period, socket) do
    par_period = socket.assigns.time_period

    Metapede.CommonSearchFuncs.add_association(
      sub_period,
      par_period,
      :sub_time_periods,
      fn el -> [el | par_period.sub_time_periods] end
    )

    {:noreply,
     socket
     |> put_flash(:info, "New Subtopic Added: #{sub_period.topic.title}")
     |> push_patch(to: Routes.time_period_show_path(socket, :show, par_period))}
  end

  def patch_for_confirm(message, new_topic, socket) do
    IO.inspect(new_topic)

    {
      :noreply,
      socket
      |> put_flash(:info, message)
      |> assign(:new_topic, new_topic)
      |> push_patch(
        to:
          Routes.time_period_show_path(
            socket,
            :confirm,
            socket.assigns.time_period.id,
            %{"new_topic_id" => new_topic.id}
          )
      )
    }
  end

  def custom_redirect({:has_time_period, topic}, socket), do: adding(topic, socket)

  def custom_redirect({:ok, new_topic}, socket),
    do: patch_for_confirm("Topic created for timeline", new_topic, socket)

  def custom_redirect({:existing, new_topic}, socket),
    do: patch_for_confirm("Topic found", new_topic, socket)

  def adding(topic, socket) do
    topic.time_period
    |> block_self_reference(socket)
    |> add_to_subtopics(socket)

    {
      :noreply,
      socket
      |> put_flash(:info, "Sub Time Period Added: #{topic.title}")
      |> push_redirect(
        to: Routes.time_period_show_path(socket, :show, socket.assigns.time_period)
      )
    }
  end

  def block_self_reference(time_period, socket) do
    if time_period.id == socket.assigns.time_period.id do
      {:self, nil}
    else
      {:not_self, time_period}
    end
  end

  def add_to_subtopics({:self, _time_period}, _socket), do: nil

  def add_to_subtopics({:not_self, time_period}, socket) do
    CommonSearchFuncs.add_association(
      time_period,
      socket.assigns.time_period,
      :sub_time_periods,
      fn el ->
        [el | socket.assigns.time_period.sub_time_periods]
      end
    )
  end

  def make_datetimes(params, prefix) do
    year = params[prefix <> "_year"]
    month = params[prefix <> "_month"] |> get_month_number
    day = params[prefix <> "_day"] #|> ensure_2digits()
    dt = format_datetime(year, month, day)
    IO.puts(dt)
    dt
  end

  def format_datetime(year, month, day), do: "#{year}-#{month}-#{day} 00:00:00"

  def ensure_2digits(entry), do: if(String.length(entry) == 1, do: "0#{entry}", else: entry)

  def get_month_number(month_abbrev) do
    months = %{
      "Jan" => "01",
      "Feb" => "02",
      "Mar" => "03",
      "Apr" => "04",
      "May" => "05",
      "Jun" => "06",
      "Jul" => "07",
      "Aug" => "08",
      "Sep" => "09",
      "Oct" => "10",
      "Nov" => "11",
      "Dec" => "12"
    }

    months[month_abbrev]
  end
end
