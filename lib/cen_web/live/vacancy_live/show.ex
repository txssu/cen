defmodule CenWeb.VacancyLive.Show do
  @moduledoc false
  use CenWeb, :live_view

  import Cen.Permissions
  import Cen.Publications.Enums

  alias Cen.Publications
  alias Cen.Publications.Vacancy

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-12">
      <div class="space-y-6 lg:grid lg:grid-flow-dense lg:grid-cols-12 lg:gap-10 lg:space-y-0">
        <.header class="lg:col-span-12" header_kind="black_left">
          <%= @vacancy.job_title %>
        </.header>

        <div class="relative pt-16 lg:order-1 lg:col-span-3 lg:col-start-10 lg:pt-0">
          <.basic_card class="px-6 pt-24 pb-14" header={dgettext("orgs", "Контакты")}>
            <img
              src={image(@vacancy.organization)}
              class="outline-[1rem] absolute top-0 left-1/2 h-32 w-32 -translate-x-1/2 rounded-full outline outline-white lg:-translate-y-1/2"
            />
            <ul class="mt-7 space-y-4">
              <%= for {value, icon} <- contacts_list(@vacancy.organization) do %>
                <.render_not_nil value={value}>
                  <li class="flex items-center gap-2.5">
                    <.icon name={icon} class="w-4 h-4" />
                    <div class="leading-[1.2] text-sm font-light text-black">
                      <%= value %>
                    </div>
                  </li>
                </.render_not_nil>
              <% end %>
            </ul>
          </.basic_card>
        </div>

        <div :if={has_permission?(@current_user, @vacancy, :update)} class="flex gap-2.5 lg:col-span-12">
          <.regular_button class="bg-accent-hover" phx-click={JS.navigate(~p"/vacancies/#{@vacancy}/edit")}>
            <%= gettext("Редактировать") %>
          </.regular_button>
          <.button class="bg-white p-4" phx-click="delete_vacancy">
            <.icon name="cen-bin" alt={dgettext("publications", "Удалить")} />
          </.button>
        </div>

        <.basic_card class="w-full px-6 py-10 lg:py-12 lg:col-span-9" header={dgettext("publications", "Описание")}>
          <p class="mt-6">
            <%= @vacancy.description %>
          </p>
        </.basic_card>

        <.basic_card class="w-full px-6 py-10 lg:py-12 lg:col-span-9">
          <div class="space-y-14">
            <%= for {header, text} <- format_vacancy_info(@vacancy) do %>
              <div>
                <p class="leading leading-[1.3] text-regulargray text-base uppercase lg:text-xl">
                  <%= header %>
                </p>
                <p class="text-regulargray mt-4"><%= text %></p>
              </div>
            <% end %>
          </div>
        </.basic_card>

        <div class="col-span-12">
          <.arrow_button arrow_direction="left" phx-click={JS.navigate(~p"/vacancies")}>
            <%= dgettext("publications", "Вернуться к вакансиям") %>
          </.arrow_button>
        </div>
      </div>
    </div>
    """
  end

  defp contacts_list(organization) do
    [
      {organization.phone_number, "cen-phone"},
      {organization.email, "cen-message"},
      {organization.address, "cen-globe"}
    ]
  end

  defp image(organization) do
    case Cen.ImageUploader.url({organization.image, organization}) do
      nil -> ~p"/images/image-placeholder.jpg"
      url -> url
    end
  end

  defp format_vacancy_info(%Vacancy{} = vacancy) do
    Enum.filter(
      [
        vacancy.proposed_salary &&
          {
            dgettext("publications", "Зарплата"),
            "#{pgettext("money", "от")} #{Publications.format_salary(vacancy.proposed_salary)}"
          },
        {
          dgettext("publications", "Тип занятости"),
          enums_to_translation(vacancy.employment_types, employment_types_translations())
        },
        {
          dgettext("publications", "График работы"),
          enums_to_translation(vacancy.work_schedules, work_schedules_translations())
        },
        {
          dgettext("publications", "Образование"),
          enum_to_translation(vacancy.education, educations_translations())
        },
        {
          dgettext("publications", "Сфера искусства"),
          enum_to_translation(vacancy.field_of_art, field_of_arts_translations())
        },
        vacancy.min_years_of_work_experience != 0 &&
          {
            dgettext("publications", "Опыт работы"),
            dngettext("publications", "от %{years} лет", "от %{years} лет", vacancy.min_years_of_work_experience,
              years: vacancy.min_years_of_work_experience
            )
          }
      ],
      & &1
    )
  end

  defp enums_to_translation(values, translations) do
    values
    |> Enum.map_join(", ", &enum_to_translation(&1, translations))
    |> String.capitalize()
  end

  defp enum_to_translation(value, translations) do
    value = to_string(value)

    translations
    |> Enum.find(fn {_ts, enum} -> enum == value end)
    |> elem(0)
  end

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    vacancy = Publications.get_vacancy!(id)
    verify_has_permission!(socket.assigns.current_user, vacancy, :show)
    {:ok, assign(socket, vacancy: vacancy)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_vacancy", _params, socket) do
    Publications.delete_vacancy(socket.assigns.vacancy)
    {:noreply, push_navigate(socket, to: ~p"/vacancies")}
  end
end
