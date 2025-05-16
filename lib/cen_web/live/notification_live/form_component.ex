defmodule CenWeb.NotificationLive.FormComponent do
  @moduledoc false
  use CenWeb, :live_component

  alias Cen.Communications

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="lg:w-[600px]">
      <.simple_form for={@form} id="notification-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:message]} type="textarea" label="Текст сообщения" />

        <:actions>
          <.arrow_button>
            <%= "Отправить уведомление" %>
          </.arrow_button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{notification: notification} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Communications.change_notification(notification))
     end)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"notification" => notification_params}, socket) do
    changeset = Communications.change_notification(socket.assigns.notification, notification_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  # Для упрощения интерфейса использую send_notification(binary()),
  # который используется дефолтные остальные параметры. В будущем есть смысл добавить
  # параметры в интерфейс
  def handle_event("save", %{"notification" => %{"message" => message}}, socket) do
    case Communications.send_notification(message) do
      {:ok, notification} ->
        notify_parent({:saved, notification})

        {:noreply,
         socket
         |> put_flash(:info, "Уведомление отправлено")
         |> push_patch(to: ~p"/notifications")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
