defmodule CenWeb.NotificationsHook do
  @moduledoc false

  import Phoenix.LiveView

  alias Cen.Communications
  alias Cen.Communications.Notification
  alias Phoenix.LiveView.Socket

  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    current_user = socket.assigns.current_user

    notifications =
      if connected?(socket) and current_user != nil do
        :ok = Communications.subscribe_to_notifications(current_user)

        Communications.list_notifications_for_user(current_user.id)
      else
        []
      end

    socket =
      socket
      |> Phoenix.Component.assign(:notifications, notifications)
      |> attach_hook(:notifications, :handle_info, &handle_info/2)

    {:cont, socket}
  end

  @spec handle_info({:new_notification, Notification.t()}, Socket.t()) :: {:cont, Socket.t()}
  def handle_info({:new_notification, notification}, socket) do
    {:halt, put_flash(socket, :info, notification.message)}
  end

  def handle_info(_message, socket) do
    {:cont, socket}
  end
end
