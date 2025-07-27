defmodule CenWeb.VacancyLive.Form do
  @moduledoc false
  use CenWeb, :live_view

  import Cen.Permissions

  alias Cen.Publications
  alias Cen.Publications.Vacancy

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-9 lg:col-start-2">
      <.simple_form for={@form} id="vacancy-form" phx-submit="save" phx-change="validate">
        <.fieldset legend={dgettext("publications", "Вакансия")}>
          <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
            <div class="lg:col-span-4 lg:col-start-1">
              <.input
                field={@form[:organization_id]}
                type="select"
                label={dgettext("publications", "Организация")}
                options={Enum.map(@organizations, &{&1.name, &1.id})}
                disabled={@live_action == :update}
                required
              />
            </div>

            <div class="lg:col-span-4 lg:col-start-1">
              <.input
                field={@form[:job_title]}
                type="text"
                label={dgettext("publications", "Кого вы ищете?")}
                placeholder={dgettext("publications", "Должность")}
                required
              />
            </div>

            <div class="lg:col-span-4 lg:col-start-6">
              <.input
                field={@form[:field_of_art]}
                type="select"
                label={dgettext("publications", "Сфера искусства")}
                options={Publications.Enums.field_of_arts_translations()}
                required
              />
            </div>
            <div class="lg:col-span-9 lg:col-start-1">
              <.input field={@form[:description]} type="textarea" label={dgettext("publications", "Описание вакансии")} required />
            </div>
            <div class="lg:col-span-4 lg:col-start-1">
              <.input
                field={@form[:employment_types]}
                type="checkbox"
                options={Publications.Enums.employment_types_translations()}
                label={dgettext("publications", "Тип занятости")}
                required
                multiple
              />
            </div>
            <div class="lg:col-span-4 lg:col-start-1">
              <.input
                field={@form[:work_schedules]}
                type="checkbox"
                options={Publications.Enums.work_schedules_translations()}
                label={dgettext("publications", "График работы")}
                name="vacancy[work_schedules][]"
                required
                multiple
              />
            </div>
            <div class="lg:col-span-4 lg:col-start-1">
              <.input
                field={@form[:education]}
                type="select"
                label={dgettext("publications", "Образование")}
                options={Publications.Enums.educations_translations()}
                required
              />
            </div>
            <div class="lg:col-span-4 lg:col-start-1">
              <div class="mt-6 w-80 space-y-2.5">
                <.input
                  field={@form[:min_years_of_work_experience]}
                  type="textcard"
                  maxlength="2"
                  label={dgettext("publications", "Опыт работы")}
                  text_before={dgettext("publications", "от")}
                  text_after={dgettext("publications", "лет")}
                />
                <.input
                  field={@form[:proposed_salary]}
                  type="textcard"
                  maxlength="6"
                  label={dgettext("publications", "Зарплата")}
                  text_before={dgettext("publications", "от")}
                  text_after="₽"
                />
              </div>
            </div>
          </div>
        </.fieldset>
        <:actions>
          <.arrow_button>
            {dgettext("forms", "Сохранить")}
          </.arrow_button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    action = socket.assigns.live_action

    organizations = Cen.Employers.list_organizations_for(socket.assigns.current_user)

    if Enum.empty?(organizations) do
      {:ok,
       socket
       |> put_flash(:error, dgettext("publications", "Сначала вам нужно создать хотя бы одну организацию"))
       |> push_navigate(to: ~p"/orgs/new")}
    else
      vacancy =
        case action do
          :create -> %Vacancy{}
          :update -> Publications.get_vacancy!(params["id"])
        end

      verify_has_permission!(socket.assigns.current_user, vacancy, action)

      {:ok, socket |> assign_form(vacancy) |> assign(organizations: organizations)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"vacancy" => vacancy_params}, socket) do
    form =
      %Vacancy{}
      |> Publications.change_vacancy(vacancy_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"vacancy" => params}, socket) do
    save_vacancy(socket, socket.assigns.live_action, params)
  end

  defp save_vacancy(socket, :create, %{"organization_id" => organization_id} = vacancy_params) do
    current_user = socket.assigns.current_user
    organization = Enum.find(socket.assigns.organizations, &(to_string(&1.id) == organization_id))

    case Publications.create_vacancy_for(current_user, organization, vacancy_params) do
      {:ok, vacancy} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/jobs/#{vacancy}")
         |> put_flash(:info, dgettext("publications", "Вакансия успешно создана."))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset), check_errors: true)}
    end
  end

  defp save_vacancy(socket, :update, vacancy_params) do
    vacancy = socket.assigns.vacancy

    case Publications.update_vacancy(vacancy, vacancy_params) do
      {:ok, _vacancy} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/jobs/#{vacancy}")
         |> put_flash(:info, dgettext("publications", "Вакансия успешно обновлена."))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp assign_form(socket, vacancy) do
    form = vacancy |> Publications.change_vacancy() |> to_form()
    assign(socket, vacancy: vacancy, form: form)
  end
end
