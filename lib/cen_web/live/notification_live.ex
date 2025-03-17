defmodule CenWeb.NotificationLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Communications

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-9">
      <div class="flex items-center">
        <.header header_kind="black_left">
          <%= gettext("Уведомления") %>
        </.header>
      </div>
      <ul class="mt-7 space-y-6">
        <%= for notification <- @notifications do %>
          <li>
            <.basic_card class="w-full py-7 px-6">
              <%= notification.message %>
            </.basic_card>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    notifications = Communications.list_notifications_for_user(socket.assigns.current_user.id)
    {:ok, assign(socket, notifications: notifications)}
  end
end
