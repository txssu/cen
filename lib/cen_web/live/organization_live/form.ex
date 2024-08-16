defmodule CenWeb.OrganizationLive.Form do
  @moduledoc false

  use CenWeb, :live_view

  alias Cen.Employers
  alias Cen.Employers.Organization

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-9 lg:col-start-2">
      <.simple_form for={@form} id="organization-form" phx-submit="save" phx-change="validate">
        <div class="space-y-9">
          <.fieldset
            legend={dgettext("orgs", "Организация")}
            subtitle={dgettext("orgs", "Общая информация")}
          >
            <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@form[:name]}
                  type="text"
                  label={dgettext("orgs", "Название организации")}
                  required
                />
              </div>
              <div class="lg:col-span-4 lg:col-start-1">
                <.input field={@form[:inn]} type="text" label={dgettext("orgs", "ИНН")} required />
              </div>
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label={dgettext("orgs", "Описание")}
                  required
                  maxlength="1000"
                />
              </div>
            </div>
          </.fieldset>

          <.fieldset legend={dgettext("orgs", "Контакты")}>
            <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@form[:phone_number]}
                  type="text"
                  label={dgettext("orgs", "Номер телефона")}
                  required
                />
              </div>
              <div class="lg:col-span-4 lg:col-start-6">
                <.input field={@form[:email]} type="email" label={dgettext("orgs", "Почта")} />
              </div>
              <div class="lg:col-span-4 lg:col-start-1">
                <.input field={@form[:address]} type="text" label={dgettext("orgs", "Адрес")} />
              </div>
            </div>
          </.fieldset>

          <.fieldset legend={dgettext("orgs", "Ссылки")}>
            <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@form[:website_link]}
                  type="text"
                  label={dgettext("orgs", "Сайт организации")}
                />
              </div>
              <div class="lg:col-span-4 lg:col-start-6">
                <.input field={@form[:social_link]} type="text" label={dgettext("orgs", "Соцсеть")} />
              </div>
            </div>
          </.fieldset>
        </div>

        <:actions>
          <.arrow_button>
            <%= dgettext("forms", "Сохранить") %>
          </.arrow_button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    organization =
      case socket.assigns.live_action do
        :create -> %Organization{}
        :update -> Employers.get_organization(params["id"])
      end

    form = organization |> Employers.change_organization() |> to_form()

    {:ok, assign(socket, organization: organization, form: form)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"organization" => organization_params}, socket) do
    form =
      %Organization{}
      |> Employers.change_organization(organization_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"organization" => organization_params}, socket) do
    save_organization(socket, socket.assigns.live_action, organization_params)
  end

  defp save_organization(socket, :create, organization_params) do
    current_user = socket.assigns.current_user

    case Employers.create_organization_for(current_user, organization_params) do
      {:ok, organization} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/organizations/#{organization}")
         |> put_flash(:info, dgettext("orgs", "Организация успешно создана."))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_organization(socket, :update, organization_params) do
    organization = socket.assigns.organization

    case Employers.update_organization(organization, organization_params) do
      {:ok, _organization} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/organizations/#{organization}")
         |> put_flash(:info, dgettext("orgs", "Организация успешно обновлена."))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
