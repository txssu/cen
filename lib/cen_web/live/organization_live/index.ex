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
          <%= title_text(@action) %>
        </.header>
        <div class="ml-auto">
          <.button class="bg-white p-4" phx-click={JS.navigate(~p"/me/orgs/new")}>
            <.icon name="cen-plus" alt={dgettext("orgs", "Создать")} />
          </.button>
        </div>
      </div>
      <ul class="mt-7 space-y-6">
        <%= for organization <- @organizations do %>
          <li>
            <.basic_card class="w-full py-7 px-6" header={organization.name}>
              <p class="text-nowrap mt-9 overflow-hidden text-ellipsis">
                <%= organization.address %>
              </p>
              <.regular_button class="bg-white w-full flex justify-center mt-5" phx-click={JS.navigate(~p"/me/orgs/#{organization}")}>
                <%= gettext("Открыть") %>
              </.regular_button>
            </.basic_card>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp title_text(action) do
    case action do
      :index -> dgettext("orgs", "Мои организации")
      :admin_index -> dgettext("orgs", "Организации")
    end
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    action = fetch_action(socket)

    verify_has_permission!(user, :organizations, action)

    organizations =
      case action do
        :index -> Employers.list_organizations_for(user)
        :admin_index -> Employers.list_organizations()
      end

    if organizations == [] do
      {:ok, push_navigate(socket, to: ~p"/me/orgs/new")}
    else
      {:ok, assign(socket, organizations: organizations, action: action)}
    end
  end

  defp fetch_action(socket) do
    case socket.assigns.live_action do
      nil -> :index
      action -> action
    end
  end
end
