defmodule CenWeb.ResumeLive.Show do
  @moduledoc false
  use CenWeb, :live_view

  import Cen.Permissions
  import Cen.Publications.Enums

  alias Cen.Publications
  alias Cen.Utils.CalendarTranslations
  alias Cen.Utils.GettextEnums

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-12">
      <div class="space-y-6 lg:grid lg:grid-flow-dense lg:grid-cols-12 lg:gap-10 lg:space-y-0">
        <.header class="lg:col-span-12" header_kind="black_left">
          <%= @resume.job_title %>
        </.header>

        <div class="relative pt-16 lg:order-1 lg:col-span-3 lg:col-start-10 lg:pt-0">
          <.basic_card class="px-6 pt-24 pb-14" header={"#{@resume.user.fullname}"}>
            <ul class="mt-7 space-y-4">
              <%= for {value, icon} <- contacts_list(@resume.user) do %>
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

        <div :if={has_permission?(@current_user, @resume, :update)} class="flex gap-2.5 lg:col-span-12">
          <.regular_button class="bg-accent-hover" phx-click={JS.navigate(~p"/resumes/#{@resume}/edit")}>
            <%= gettext("Редактировать") %>
          </.regular_button>
          <.button class="bg-white p-4" phx-click="delete_resume">
            <.icon name="cen-bin" alt={dgettext("publications", "Удалить")} />
          </.button>
        </div>

        <.basic_card class="w-full px-6 py-10 lg:py-12 lg:col-span-9" header={dgettext("publications", "Описание")}>
          <p class="mt-6">
            <%= @resume.description %>
          </p>
        </.basic_card>

        <.basic_card class="w-full px-6 py-10 lg:py-12 lg:col-span-9">
          <div class="space-y-14">
            <div>
              <p class="leading leading-[1.3] text-regulargray text-base uppercase lg:text-xl">
                <%= dgettext("publications", "Тип занятости") %>
              </p>
              <p class="mt-4"><%= GettextEnums.enums_to_translation(@resume.employment_types, employment_types_translations()) %></p>
            </div>
            <div>
              <p class="leading leading-[1.3] text-regulargray text-base uppercase lg:text-xl">
                <%= dgettext("publications", "График работы") %>
              </p>
              <p class="mt-4"><%= GettextEnums.enums_to_translation(@resume.work_schedules, work_schedules_translations()) %></p>
            </div>
            <div>
              <p class="leading leading-[1.3] text-regulargray text-base uppercase lg:text-xl">
                <%= dgettext("publications", "Образование") %>
              </p>
              <ul class="mt-4 space-y-4">
                <li :for={education <- @resume.educations}>
                  <p><%= GettextEnums.enum_to_translation(education.level, educations_translations()) %></p>
                  <p><%= education.educational_institution %>, <%= education.year_of_graduation %></p>
                  <p><%= education.department %></p>
                  <p><%= education.specialization %></p>
                </li>
              </ul>
            </div>
            <div>
              <p class="leading leading-[1.3] text-regulargray text-base uppercase lg:text-xl">
                <%= dgettext("publications", "Опыт работы") %>
              </p>
              <ul class="mt-4 space-y-4">
                <li :for={education <- @resume.jobs}>
                  <p class="text-accent"><%= format_date_range(education.start_date, education.end_date) %></p>
                  <p><%= education.organization_name %></p>
                  <p><%= education.job_title %></p>
                  <p><%= education.description %></p>
                </li>
              </ul>
            </div>
          </div>
        </.basic_card>

        <div class="col-span-12">
          <.arrow_button arrow_direction="left" phx-click={JS.navigate(@back_link)}>
            <%= dgettext("publications", "Вернуться к списку резюме") %>
          </.arrow_button>
        </div>
      </div>
    </div>
    """
  end

  defp contacts_list(user) do
    [
      {user.email, "cen-message"},
      {user.phone_number, "cen-phone"}
    ]
  end

  defp format_date_range(start_date, end_date) do
    "#{format_date(start_date)} - #{format_date(end_date)}"
  end

  defp format_date(date) when is_nil(date), do: gettext("Настоящее")

  defp format_date(date) do
    Calendar.strftime(date, "%B %Y", month_names: &CalendarTranslations.month_names/1)
  end

  @impl Phoenix.LiveView
  def mount(%{"id" => id} = params, _session, socket) do
    resume = Publications.get_resume!(id)
    verify_has_permission!(socket.assigns.current_user, resume, :show)

    back_link = get_back_link(params)

    {:ok, assign(socket, resume: resume, back_link: back_link)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_resume", _params, socket) do
    Publications.delete_resume(socket.assigns.resume)
    {:noreply, push_navigate(socket, to: socket.assigns.back_link)}
  end

  defp get_back_link(params) do
    case params do
      %{"back" => "search"} -> ~p"/resumes/search"
      _other -> ~p"/resumes"
    end
  end
end
