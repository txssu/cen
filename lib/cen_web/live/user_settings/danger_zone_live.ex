defmodule CenWeb.UserSettings.DangerZoneLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts
  alias CenWeb.UserSettings.Components

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-3">
      <Components.navigation current_page={:danger_zone} />
    </div>

    <div class="col-span-4 lg:col-start-5">
      <section class="mt-[2.1875rem]">
        <.header header_level="h2" header_kind="black_left">
          {dgettext("users", "Удаление аккаунта")}
        </.header>

        <div class="mt-4 rounded-lg border border-red-200 bg-red-50 p-4">
          <p class="mb-4 text-red-800">
            {dgettext("users", "Внимание! Удаление аккаунта необратимо.")}
          </p>
          <p class="mb-4 text-sm text-red-700">
            {dgettext("users", "После удаления аккаунта:")}
          </p>
          <ul class="mb-4 list-inside list-disc text-sm text-red-700">
            <li>{dgettext("users", "Ваш профиль станет недоступен")}</li>
            <li>{dgettext("users", "Все ваши вакансии и резюме будут скрыты")}</li>
            <li>{dgettext("users", "Восстановление будет невозможно")}</li>
          </ul>

          <.button class="rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700" phx-click="confirm_delete">
            {dgettext("users", "Удалить аккаунт")}
          </.button>
        </div>
      </section>
    </div>

    <.modal :if={@show_confirm_modal} show id="confirm_delete_modal" on_cancel={JS.push("cancel_delete")}>
      <div class="text-center">
        <.icon name="cen-trash-xmark" class="mx-auto mb-4 h-12 w-12 text-red-500" />
        <h3 class="mb-4 text-lg font-medium text-gray-900">
          {dgettext("users", "Подтвердите удаление аккаунта")}
        </h3>
        <p class="mb-6 text-sm text-gray-500">
          {dgettext("users", "Это действие нельзя отменить. Все ваши данные будут безвозвратно удалены.")}
        </p>
        <div class="flex justify-center gap-3">
          <.button class="rounded bg-gray-300 px-4 py-2 text-gray-800 hover:bg-gray-400" phx-click="cancel_delete">
            {dgettext("users", "Отмена")}
          </.button>
          <.button class="rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700" phx-click="delete_account">
            {dgettext("users", "Да, удалить")}
          </.button>
        </div>
      </div>
    </.modal>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, show_confirm_modal: false)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("confirm_delete", _params, socket) do
    {:noreply, assign(socket, show_confirm_modal: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_confirm_modal: false)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_account", _params, socket) do
    user = socket.assigns.current_user

    case Accounts.soft_delete_user(user) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("users", "Ваш аккаунт был успешно удален."))
         |> redirect(to: ~p"/")}

      :error ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("users", "Произошла ошибка при удалении аккаунта."))
         |> assign(show_confirm_modal: false)}
    end
  end
end
