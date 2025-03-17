defmodule CenWeb.NotificationsComponent do
  @moduledoc false
  use CenWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="absolute top-4 right-0">
      <div class="shadow-default-1 w-[630px] rounded-lg bg-white p-5">
        <div class="flex">
          <p class="text-title-text text-xl font-medium uppercase">
            <%= dgettext("publications", "Уведомления") %>
          </p>
          <button class="text-accent ml-auto" phx-click="read_notifications">
            <%= dgettext("publications", "Пометить прочитанными") %>
          </button>
        </div>
        <ul class="mt-7 space-y-4">
          <li :for={notification <- @unread_notifications}>
            <div class="shadow-notification-card flex gap-12 rounded-lg px-2.5 py-4">
              <div class="flex w-6 shrink-0 items-center">
                <.notification_icon type={notification.type} />
              </div>
              <div class="flex items-center">
                <p>
                  <%= notification.message %>
                </p>
              </div>
            </div>
          </li>
          <li :if={@unread_notifications == []}>
            <p class="mb-4">
              <%= dgettext("publications", "У вас нет непрочитанных уведомлений") %>
            </p>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp notification_icon(assigns)

  defp notification_icon(%{type: :success} = assigns) do
    ~H"""
    <.icon name="cen-success" class="h-6 w-6" />
    """
  end

  defp notification_icon(%{type: :warning} = assigns) do
    ~H"""
    <.icon name="cen-warning" class="h-6 w-6" />
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
