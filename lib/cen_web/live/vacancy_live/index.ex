defmodule CenWeb.VacancyLive.Index do
  @moduledoc false

  use CenWeb, :live_view

  import Cen.Permissions

  alias Cen.Publications

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <div class="flex items-center">
        <.header header_kind="black_left">
          <%= dgettext("publications", "Мои вакансии") %>
        </.header>
        <div class="ml-auto">
          <.button class="bg-white p-4" phx-click={JS.navigate(~p"/vacancies/new")}>
            <.icon name="cen-plus" alt={gettext("Создать")} />
          </.button>
        </div>
      </div>
      <ul class="mt-7 space-y-6">
        <%= for vacancy <- @vacancies do %>
          <li>
            <.basic_card class="w-full py-7 px-6" header={vacancy.job_title}>
              <p :if={vacancy.proposed_salary} class="text-title-text mt-2.5">
                <%= pgettext("money", "от") %> <%= Publications.format_salary(vacancy.proposed_salary) %>
              </p>
              <p class="text-nowrap mt-9 overflow-hidden text-ellipsis">
                <%= vacancy.organization.name %>
              </p>
              <.regular_button class="bg-white w-full flex justify-center mt-5" phx-click={JS.navigate(~p"/vacancies/#{vacancy}")}>
                <%= gettext("Открыть") %>
              </.regular_button>
            </.basic_card>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    verify_has_permission!(user, :vacancies, :index)
    vacancies = Publications.list_vacancies_for(user)

    if vacancies == [] do
      {:ok, push_navigate(socket, to: ~p"/vacancies/new")}
    else
      {:ok, assign(socket, vacancies: vacancies)}
    end
  end
end
