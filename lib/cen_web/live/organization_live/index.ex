defmodule CenWeb.OrganizationLive.Index do
  @moduledoc false

  use CenWeb, :live_view

  import Cen.Permissions

  alias Cen.Employers

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <div class="flex items-center">
        <.header header_kind="black_left">
          {title_text(@current_user.role)}
        </.header>
        <div class="ml-auto">
          <.button class="bg-white p-4" phx-click={JS.navigate(~p"/orgs/new")}>
            <.icon name="cen-plus" alt={dgettext("orgs", "Создать")} />
          </.button>
        </div>
      </div>
      <ul class="mt-7 space-y-6">
        <li :for={organization <- @organizations} :key={organization.id}>
          <.basic_card class="w-full px-6 py-7" header={organization.name}>
            <p class="text-nowrap mt-9 overflow-hidden text-ellipsis">
              {organization.address}
            </p>
            <.regular_button class="mt-5 flex w-full justify-center bg-white" phx-click={JS.navigate(~p"/orgs/#{organization}")}>
              {gettext("Открыть")}
            </.regular_button>
          </.basic_card>
        </li>
      </ul>
    </div>
    """
  end

  defp title_text(role) do
    case role do
      :admin -> dgettext("orgs", "Организации")
      _other -> dgettext("orgs", "Мои организации")
    end
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    verify_has_permission!(user, :organizations, :index)

    organizations =
      case user.role do
        :admin -> Employers.list_organizations()
        _other -> Employers.list_organizations_for(user)
      end

    if organizations == [] and user.role != :admin do
      {:ok, push_navigate(socket, to: ~p"/orgs/new")}
    else
      {:ok, assign(socket, organizations: organizations, current_user: user)}
    end
  end
end
