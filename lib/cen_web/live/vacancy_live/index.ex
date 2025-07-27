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
          {@title}
        </.header>
        <%= if @live_action == :index_for_user do %>
          <div class="ml-auto">
            <.button class="bg-white p-4" phx-click={JS.navigate(~p"/jobs/new")}>
              <.icon name="cen-plus" alt={gettext("Создать")} />
            </.button>
          </div>
        <% end %>
      </div>
      <ul class="mt-7 space-y-6">
        <%= for vacancy <- @vacancies do %>
          <li>
            <.basic_card class="w-full px-6 py-7" header={vacancy.job_title}>
              <p :if={vacancy.proposed_salary} class="text-title-text mt-2.5">
                {pgettext("money", "от")} {Publications.format_salary(vacancy.proposed_salary)}
              </p>
              <p class="text-nowrap mt-9 overflow-hidden text-ellipsis">
                {vacancy.organization.name}
              </p>
              <.regular_button class="mt-5 flex w-full justify-center bg-white" phx-click={JS.navigate(~p"/jobs/#{vacancy}")}>
                {gettext("Открыть")}
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
    action = socket.assigns.live_action

    verify_has_permission!(socket.assigns.current_user, :vacancies, action)

    {:ok,
     socket
     |> assign_title(action)
     |> load_vacancies(action)
     |> assign(action: action)}
  end

  defp assign_title(socket, live_action) do
    case live_action do
      :index_for_user -> assign(socket, :title, dgettext("publications", "Мои вакансии"))
      :index_for_review -> assign(socket, :title, dgettext("publications", "Вакансии на проверке"))
    end
  end

  defp load_vacancies(socket, :index_for_user) do
    vacancies = Publications.list_vacancies_for(socket.assigns.current_user)

    if vacancies == [] do
      push_navigate(socket, to: ~p"/jobs/new")
    else
      assign(socket, vacancies: vacancies)
    end
  end

  defp load_vacancies(socket, :index_for_review) do
    vacancies = Publications.list_not_reviewed_vacancies()
    assign(socket, vacancies: vacancies)
  end
end
