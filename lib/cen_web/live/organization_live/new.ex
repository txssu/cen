defmodule CenWeb.OrganizationLive.New do
  @moduledoc false

  use CenWeb, :live_view

  alias Cen.Employers
  alias Cen.Employers.Organization

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 lg:col-span-9 lg:col-start-2">
      <.simple_form
        for={@organization_form}
        id="organization_form"
        phx-submit="create_organization"
        phx-change="validate_organization"
      >
        <div class="space-y-9">
          <.fieldset
            legend={dgettext("orgs", "Организация")}
            subtitle={dgettext("orgs", "Общая информация")}
          >
            <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@organization_form[:name]}
                  type="text"
                  label={dgettext("orgs", "Название организации")}
                  required
                />
              </div>
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@organization_form[:inn]}
                  type="text"
                  label={dgettext("orgs", "ИНН")}
                  required
                />
              </div>
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@organization_form[:description]}
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
                  field={@organization_form[:phone_number]}
                  type="text"
                  label={dgettext("orgs", "Номер телефона")}
                  required
                />
              </div>
              <div class="lg:col-span-4 lg:col-start-6">
                <.input
                  field={@organization_form[:email]}
                  type="email"
                  label={dgettext("orgs", "Почта")}
                />
              </div>
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@organization_form[:address]}
                  type="text"
                  label={dgettext("orgs", "Адрес")}
                />
              </div>
            </div>
          </.fieldset>

          <.fieldset legend={dgettext("orgs", "Ссылки")}>
            <div class="lg:grid lg:grid-cols-9 lg:gap-x-10">
              <div class="lg:col-span-4 lg:col-start-1">
                <.input
                  field={@organization_form[:website_link]}
                  type="text"
                  label={dgettext("orgs", "Сайт организации")}
                />
              </div>
              <div class="lg:col-span-4 lg:col-start-6">
                <.input
                  field={@organization_form[:social_link]}
                  type="text"
                  label={dgettext("orgs", "Соцсеть")}
                />
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
  def mount(_params, _session, socket) do
    organization_form =
      %Organization{}
      |> Employers.change_organization()
      |> to_form()

    {:ok, assign(socket, organization_form: organization_form)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_organization", %{"organization" => organization_params}, socket) do
    organization_form =
      %Organization{}
      |> Employers.change_organization(organization_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, organization_form: organization_form)}
  end

  def handle_event("create_organization", %{"organization" => organization_params}, socket) do
    current_user = socket.assigns.current_user

    case Employers.create_organization_for(current_user, organization_params) do
      {:ok, _organization} ->
        {:noreply, put_flash(socket, :info, dgettext("orgs", "Организация успешно создана."))}

      {:error, changeset} ->
        {:noreply, assign(socket, organization_form: to_form(changeset))}
    end
  end
end
