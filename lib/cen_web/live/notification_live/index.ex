defmodule CenWeb.NotificationLive.Index do
  @moduledoc false
  use CenWeb, :live_view

  import Cen.Permissions

  alias Cen.Communications
  alias Cen.Communications.Notification

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-9">
      <div class="flex items-center">
        <.header header_kind="black_left">
          {gettext("Уведомления")}
        </.header>
        <div :if={has_permission?(@current_user, %Notification{}, :new)} class="ml-auto">
          <.button class="bg-white p-4" phx-click={JS.navigate(~p"/notifications/new")}>
            <.icon name="cen-plus" alt="Создать" />
          </.button>
        </div>
      </div>
      <ul class="mt-7 space-y-6" id="notifications" phx-update="stream">
        <li :for={{id, notification} <- @streams.notifications} id={id}>
          <.basic_card class="w-full px-6 py-7">
            {notification.message}
          </.basic_card>
        </li>
      </ul>
    </div>
    <.modal :if={@live_action == :new} id="send_notification" on_cancel={JS.navigate(~p"/notifications")} show>
      <.live_component module={CenWeb.NotificationLive.FormComponent} id="new" notification={@notification} />
    </.modal>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    notifications = Communications.list_notifications_for_user(socket.assigns.current_user.id)
    {:ok, stream(socket, :notifications, notifications)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  @impl Phoenix.LiveView
  def handle_info({CenWeb.NotificationLive.FormComponent, {:saved, notification}}, socket) do
    {:noreply, stream_insert(socket, :notifications, notification, at: 0)}
  end

  defp apply_action(socket, :new) do
    notification = %Notification{}
    verify_has_permission!(socket.assigns.current_user, notification, :new)

    socket
    |> assign(:page_title, "Отправить уведомление")
    |> assign(:notification, notification)
  end

  defp apply_action(socket, :index) do
    socket
    |> assign(:page_title, "Уведомления")
    |> assign(:notification, nil)
  end
end
