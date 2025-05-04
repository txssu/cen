defmodule CenWeb.NotificationsHook do
  @moduledoc false

  import Phoenix.LiveView

  alias Cen.Communications
  alias Phoenix.LiveView.Socket

  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    current_user = socket.assigns.current_user

    unread_notifications =
      if connected?(socket) and current_user != nil do
        :ok = Communications.subscribe_to_notifications(current_user)

        Communications.list_unread_notifications_for_user(current_user.id)
      else
        []
      end

    socket =
      socket
      |> Phoenix.Component.assign(:unread_notifications, unread_notifications)
      |> attach_hook(:notifications_component, :handle_event, &handle_event/3)
      |> attach_hook(:notifications, :handle_info, &handle_info/2)

    {:cont, socket}
  end

  @spec handle_event(String.t(), map(), Socket.t()) :: {:cont | :halt, Socket.t()}
  def handle_event("read_notifications", _unsigned_params, socket) do
    send_update(CenWeb.NotificationsComponent, %{id: "notifications", unread_notifications: []})
    {:halt, socket}
  end

  def handle_event(_event, _params, socket) do
    {:cont, socket}
  end

  @spec handle_info(term(), Socket.t()) :: {:cont | :halt, Socket.t()}
  def handle_info({:new_notification, notification}, socket) do
    unread_notifications = [notification | socket.assigns.unread_notifications]

    {:halt,
     socket
     |> Phoenix.Component.assign(:unread_notifications, unread_notifications)
     |> put_flash(:info, notification.message)}
  end

  def handle_info(_message, socket) do
    {:cont, socket}
  end
end
