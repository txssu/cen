defmodule CenWeb.ResumeLive.Form do
  @moduledoc false

  use CenWeb, :live_view

  import Cen.Permissions

  alias Cen.Publications
  alias Cen.Publications.Resume

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-9 lg:col-start-2">
      <.simple_form for={@form} id="vacancy-form" phx-submit="save" phx-change="validate">
        <.fieldset legend={dgettext("publications", "Резюме")}>
          <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
            <div class="lg:col-span-4 lg:col-start-1">
              <.input
                field={@form[:job_title]}
                type="text"
                label={dgettext("publications", "Какую работу вы ищете?")}
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
              <.input field={@form[:description]} type="textarea" label={dgettext("publications", "О себе")} required />
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

            <div class="lg:col-span-4 lg:col-start-6">
              <.input
                field={@form[:work_schedules]}
                type="checkbox"
                options={Publications.Enums.work_schedules_translations()}
                label={dgettext("publications", "График работы")}
                required
                multiple
              />
            </div>
          </div>
          <div class="lg:col-span-9">
            <.fieldset class="pt-9" legend={dgettext("publications", "Образование")}>
              <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
                <.inputs_for :let={education} field={@form[:educations]}>
                  <hr :if={education.index != 0} class="border-accent mt-6 border-2 lg:col-span-9" />
                  <input type="hidden" name="resume[educations_order][]" value={education.index} />

                  <div class="lg:col-span-4 lg:col-start-1">
                    <.input
                      field={education[:level]}
                      type="select"
                      label={dgettext("publications", "Уровень образования")}
                      options={Publications.Enums.resume_educations_translations()}
                      required
                    />
                  </div>

                  <div class="lg:col-span-4 lg:col-start-6">
                    <.input
                      field={education[:educational_institution]}
                      type="text"
                      label={dgettext("publications", "Название учебного заведения")}
                      required
                    />
                  </div>

                  <div class="lg:col-span-4 lg:col-start-1">
                    <.input field={education[:department]} type="text" label={dgettext("publications", "Факультет")} />
                  </div>

                  <div class="lg:col-span-4 lg:col-start-6">
                    <.input field={education[:specialization]} type="text" label={dgettext("publications", "Специализация")} required />
                  </div>

                  <div class="lg:col-span-4 lg:col-start-1">
                    <.input field={education[:year_of_graduation]} type="text" label={dgettext("publications", "Год окончания")} required />
                  </div>

                  <div class="lg:col-span-9 lg:col-start-1">
                    <.regular_button
                      :if={education.index != 0}
                      class="mt-4"
                      type="button"
                      name="resume[educations_drop][]"
                      value={education.index}
                      phx-click={JS.dispatch("change")}
                    >
                      <%= dgettext("misc", "Удалить") %>
                    </.regular_button>
                  </div>
                </.inputs_for>
              </div>
              <input type="hidden" name="resume[educations_drop][]" />
              <.arrow_button type="button" name="resume[educations_order][]" value="new" class="mt-4" phx-click={JS.dispatch("change")}>
                <%= gettext("Добавить ещё") %>
              </.arrow_button>
            </.fieldset>
          </div>

          <div class="lg:col-span-9">
            <.fieldset class="pt-9" legend={dgettext("publications", "Опыт работы")}>
              <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
                <.inputs_for :let={job} field={@form[:jobs]}>
                  <hr :if={job.index != 0} class="border-accent mt-6 border-2 lg:col-span-9" />
                  <input type="hidden" name="resume[jobs_order][]" value={job.index} />

                  <div class="lg:col-span-4 lg:col-start-1">
                    <.input field={job[:job_title]} type="text" label={dgettext("publications", "Должность")} required />
                  </div>

                  <div class="lg:col-span-4 lg:col-start-6">
                    <.input field={job[:description]} type="text" label={dgettext("publications", "Обязанности, достижения")} />
                  </div>

                  <div class="lg:col-span-4 lg:col-start-1">
                    <.input field={job[:start_month]} type="month" label={dgettext("publications", "Начало работы")} required />
                  </div>

                  <div class="lg:col-span-4 lg:col-start-6">
                    <.input
                      field={job[:end_month]}
                      type="month"
                      label={dgettext("publications", "Окончание")}
                      placeholder="Оставьте пустым, если ещё работаете"
                    />
                  </div>

                  <div class="lg:col-span-4 lg:col-start-1">
                    <.input field={job[:organization_name]} type="text" label={dgettext("publications", "Название организации")} />
                  </div>

                  <div class="lg:col-span-9 lg:col-start-1">
                    <.regular_button type="button" class="mt-4" name="resume[jobs_drop][]" value={job.index} phx-click={JS.dispatch("change")}>
                      <%= gettext("Удалить") %>
                    </.regular_button>
                  </div>
                </.inputs_for>
              </div>
              <input type="hidden" name="resume[jobs_drop][]" />
              <.arrow_button type="button" name="resume[jobs_order][]" value="new" class="mt-4" phx-click={JS.dispatch("change")}>
                <%= gettext("Добавить") %>
              </.arrow_button>
            </.fieldset>
          </div>
        </.fieldset>

        <:actions>
          <.arrow_button>
            <%= dgettext("publications", "Сохранить резюме") %>
          </.arrow_button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    action = socket.assigns.live_action

    resume =
      case action do
        :create -> %Resume{educations: [%Resume.Education{}]}
        :update -> Publications.get_resume!(params["id"])
      end

    verify_has_permission!(socket.assigns.current_user, resume, action)

    {:ok, assign_form(socket, resume)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"resume" => resume_params}, socket) do
    form =
      %Resume{}
      |> Publications.change_resume(resume_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"resume" => resume_params}, socket) do
    save_resume(socket, socket.assigns.live_action, resume_params)
  end

  defp save_resume(socket, :create, resume_params) do
    current_user = socket.assigns.current_user

    case Publications.create_resume_for(current_user, resume_params) do
      {:ok, resume} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/cvs/#{resume}")
         |> put_flash(:info, dgettext("publications", "Резюме успешно создано."))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_resume(socket, :update, resume_params) do
    resume = socket.assigns.resume

    case Publications.update_resume(resume, resume_params) do
      {:ok, _resume} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/cvs/#{resume}")
         |> put_flash(:info, dgettext("publications", "Резюме успешно обновлено."))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp assign_form(socket, resume) do
    form = resume |> Publications.change_resume() |> to_form()
    assign(socket, resume: resume, form: form)
  end
end
