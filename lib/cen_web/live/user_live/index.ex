defmodule CenWeb.UserLive.Index do
  @moduledoc false

  use CenWeb, :live_view

  import Cen.Permissions

  alias Cen.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <div class="flex items-center">
        <.header header_kind="black_left">
          {dgettext("users", "Пользователи")}
        </.header>
      </div>
      <ul class="mt-7 space-y-6">
        <li :for={user <- @users} :key={user.id}>
          <.basic_card class="w-full px-6 py-7" header={user.email}>
            <p class="text-nowrap mt-9 overflow-hidden text-ellipsis">
              {dgettext("users", "Роль:")} {translate_role(user.role)}
            </p>
          </.basic_card>
        </li>
      </ul>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    verify_has_permission!(user, :users, :index)

    users = Accounts.list_users()

    {:ok, assign(socket, users: users)}
  end

  defp translate_role(:admin), do: dgettext("users", "Администратор")
  defp translate_role(:employer), do: dgettext("users", "Работодатель")
  defp translate_role(:applicant), do: dgettext("users", "Соискатель")
  defp translate_role(role), do: to_string(role)
end
