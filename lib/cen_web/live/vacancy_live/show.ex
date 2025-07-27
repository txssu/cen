defmodule CenWeb.VacancyLive.Show do
  @moduledoc false
  use CenWeb, :live_view

  import Cen.Permissions
  import Cen.Publications.Enums

  alias Cen.Communications
  alias Cen.Publications
  alias Cen.Publications.Vacancy

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-12">
      <div class="space-y-6 lg:grid lg:grid-flow-dense lg:grid-cols-12 lg:gap-10 lg:space-y-0">
        <.header class="lg:col-span-12" header_kind="black_left">
          {@vacancy.job_title}
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
                    <.icon name={icon} class="h-4 w-4" />
                    <div class="leading-[1.2] text-sm font-light text-black">
                      {value}
                    </div>
                  </li>
                </.render_not_nil>
              <% end %>
            </ul>
          </.basic_card>
        </div>

        <div class="space-y-4 lg:col-span-12">
          <div class="flex gap-2.5">
            <%= if has_permission?(@current_user, @vacancy, :update) do %>
              <.regular_button class="bg-accent-hover" phx-click={JS.navigate(~p"/jobs/#{@vacancy}/edit")}>
                {gettext("Редактировать")}
              </.regular_button>
              <.button class="bg-white p-4" phx-click="delete_vacancy">
                <.icon name="cen-bin" alt={dgettext("publications", "Удалить")} />
              </.button>
            <% end %>
            <%= if @current_user.role == :applicant do %>
              <.regular_button class="bg-accent-hover" phx-click={JS.navigate(~p"/jobs/#{@vacancy}/choose_resume")}>
                {dgettext("publications", "Откликнуться")}
              </.regular_button>
            <% end %>
          </div>
          <%= if has_permission?(@current_user, @vacancy, :review) do %>
            <div class="flex gap-2.5">
              <%= if @vacancy.reviewed_at do %>
                <.regular_button class="bg-accent-hover" phx-click="unapprove_vacancy">
                  {gettext("На проверку")}
                </.regular_button>
              <% else %>
                <.regular_button class="bg-accent-hover" phx-click="approve_vacancy">
                  {gettext("Одобрить")}
                </.regular_button>
              <% end %>
            </div>
          <% end %>
        </div>

        <.basic_card class="w-full px-6 py-10 lg:col-span-9 lg:py-12" header={dgettext("publications", "Описание")}>
          <p class="mt-6">
            {@vacancy.description}
          </p>
        </.basic_card>

        <.basic_card class="w-full px-6 py-10 lg:col-span-9 lg:py-12">
          <div class="space-y-14">
            <%= for {header, text} <- format_vacancy_info(@vacancy) do %>
              <div>
                <p class="leading leading-[1.3] text-regulargray text-base uppercase lg:text-xl">
                  {header}
                </p>
                <p class="mt-4">{text}</p>
              </div>
            <% end %>
          </div>
        </.basic_card>
      </div>
    </div>

    <.modal id="choose_resume" show={@show_resume_modal} on_cancel={JS.patch(~p"/jobs/#{@vacancy}")}>
      <.header class="mb-4" header_kind="black_left">
        {dgettext("publications", "Выберите резюме")}
        <.simple_form for={@select_resume_form} phx-submit="choose_resume">
          <.input field={@select_resume_form[:resume_id]} type="select" options={@resumes |> Enum.map(&{&1.job_title, &1.id})} />

          <.input field={@select_resume_form[:message_text]} type="textarea" label={dgettext("publications", "Сообщение")} />

          <:actions>
            <.arrow_button>
              {dgettext("publications", "Отправить")}
            </.arrow_button>
          </:actions>
        </.simple_form>
      </.header>
    </.modal>
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

    {:ok, assign(socket, vacancy: vacancy, select_resume_form: to_form(%{}, as: "select_resume_form"), resumes: [])}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, assign_interactions(socket)}
  end

  defp assign_interactions(socket) do
    case socket.assigns.live_action do
      :show -> assign(socket, show_resume_modal: false)
      :choose_resume -> socket |> assign(show_resume_modal: true) |> maybe_send_interaction()
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_vacancy", _params, socket) do
    Publications.delete_vacancy(socket.assigns.vacancy)
    {:noreply, push_navigate(socket, to: ~p"/jobs")}
  end

  def handle_event("choose_resume", %{"select_resume_form" => select_resume_params}, socket) do
    %{"resume_id" => resume_id, "message_text" => message_text} = select_resume_params
    resume = Enum.find(socket.assigns.resumes, &(&1.id == String.to_integer(resume_id)))
    {:noreply, send_interaction(resume, message_text, socket)}
  end

  def handle_event("approve_vacancy", _params, socket) do
    vacancy = Publications.approve_vacancy(socket.assigns.vacancy)
    {:noreply, assign(socket, vacancy: vacancy)}
  end

  def handle_event("unapprove_vacancy", _params, socket) do
    vacancy = Publications.unapprove_vacancy(socket.assigns.vacancy)
    {:noreply, assign(socket, vacancy: vacancy)}
  end

  defp maybe_send_interaction(socket) do
    socket.assigns.current_user
    |> Publications.list_resumes_for()
    |> send_interaction(socket)
  end

  defp send_interaction([], socket) do
    socket
    |> put_flash(:error, dgettext("publications", "Сначала вам нужно создать хотя бы одно резюме"))
    |> push_navigate(to: ~p"/cvs")
  end

  defp send_interaction(resumes, socket) do
    assign(socket, resumes: resumes)
  end

  defp send_interaction(resume, message_text, socket) do
    vacancy = socket.assigns.vacancy

    user_id = socket.assigns.current_user.id

    message_attrs = %{user_id: user_id, text: message_text}

    url_fun = fn
      :vacancy, id -> url(~p"/invs/jobs/#{id}")
      :resume, id -> url(~p"/res/cvs/#{id}")
    end

    case Communications.create_interaction_from_resume(
           resume: resume,
           vacancy: vacancy,
           message_attrs: message_attrs,
           url_fun: url_fun
         ) do
      {:ok, _interaction} ->
        socket |> put_flash(:info, dgettext("publications", "Отклик успешно отправлен")) |> push_navigate(to: ~p"/jobs/#{vacancy}")

      {:error, _changeset} ->
        socket |> put_flash(:error, dgettext("publications", "Вы уже отправили отклик")) |> push_navigate(to: ~p"/jobs/#{vacancy}")
    end
  end
end
