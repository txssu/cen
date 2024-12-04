defmodule CenWeb.ResumeLive.Show do
  @moduledoc false
  use CenWeb, :live_view

  import Cen.Permissions
  import Cen.Publications.Enums

  alias Cen.Communications
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

        <div class="flex gap-2.5 lg:col-span-12">
          <%= if has_permission?(@current_user, @resume, :update) do %>
            <.regular_button class="bg-accent-hover" phx-click={JS.navigate(~p"/cvs/#{@resume}/edit")}>
              <%= gettext("Редактировать") %>
            </.regular_button>
            <.button class="bg-white p-4" phx-click="delete_resume">
              <.icon name="cen-bin" alt={dgettext("publications", "Удалить")} />
            </.button>
          <% end %>
          <%= if @current_user.role == :employer do %>
            <.regular_button class="bg-accent-hover" phx-click={JS.navigate(~p"/cvs/#{@resume}/choose_vacancy")}>
              <%= dgettext("publications", "Пригласить") %>
            </.regular_button>
          <% end %>
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
      </div>
    </div>

    <.modal id="choose_vacancy" show={@show_vacancy_modal} on_cancel={JS.patch(~p"/cvs/#{@resume}")}>
      <.header class="mb-4" header_kind="black_left">
        <%= dgettext("publications", "Выберите вакансию") %>
        <.simple_form for={@select_vacancy_form} phx-submit="choose_vacancy">
          <.input field={@select_vacancy_form[:vacancy_id]} type="select" options={@vacancies |> Enum.map(&{&1.job_title, &1.id})} />

          <.input field={@select_vacancy_form[:message_text]} type="textarea" label={dgettext("publications", "Сообщение")} />

          <:actions>
            <.arrow_button>
              <%= dgettext("publications", "Выбрать") %>
            </.arrow_button>
          </:actions>
        </.simple_form>
      </.header>
    </.modal>
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
  def mount(%{"id" => id}, _session, socket) do
    resume = Publications.get_resume!(id)
    verify_has_permission!(socket.assigns.current_user, resume, :show)

    {:ok, assign(socket, resume: resume, select_vacancy_form: to_form(%{}, as: "select_vacancy_params"), vacancies: [])}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, assign_interactions(socket)}
  end

  defp assign_interactions(socket) do
    case socket.assigns.live_action do
      :show -> assign(socket, show_vacancy_modal: false)
      :choose_vacancy -> socket |> assign(show_vacancy_modal: true) |> maybe_send_interaction()
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_resume", _params, socket) do
    Publications.delete_resume(socket.assigns.resume)
    {:noreply, push_navigate(socket, to: ~p"/cvs")}
  end

  def handle_event("choose_vacancy", %{"select_vacancy_params" => select_vacancy_params}, socket) do
    %{"vacancy_id" => vacancy_id, "message_text" => message_text} = select_vacancy_params
    vacancy = Enum.find(socket.assigns.vacancies, &(&1.id == String.to_integer(vacancy_id)))
    {:noreply, send_interaction(vacancy, message_text, socket)}
  end

  defp maybe_send_interaction(socket) do
    socket.assigns.current_user
    |> Publications.list_vacancies_for()
    |> send_interaction(socket)
  end

  defp send_interaction([], socket) do
    socket
    |> put_flash(:error, dgettext("publications", "Сначала вам нужно создать хотя бы одно резюме"))
    |> push_navigate(to: ~p"/jobs")
  end

  defp send_interaction(vacancies, socket) do
    assign(socket, vacancies: vacancies)
  end

  defp send_interaction(vacancy, message_text, socket) do
    resume = socket.assigns.resume
    user_id = socket.assigns.current_user.id

    message_attrs = %{user_id: user_id, text: message_text}

    case Communications.create_interaction_from_vacancy(vacancy: vacancy, resume: resume, message_attrs: message_attrs) do
      {:ok, _interaction} ->
        socket |> put_flash(:info, dgettext("publications", "Отклик успешно отправлен")) |> push_navigate(to: ~p"/cvs/#{resume}")

      {:error, _changeset} ->
        socket |> put_flash(:error, dgettext("publications", "Вы уже отправили отклик")) |> push_navigate(to: ~p"/cvs/#{resume}")
    end
  end
end
