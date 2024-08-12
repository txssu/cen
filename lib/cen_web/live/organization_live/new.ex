defmodule CenWeb.OrganizationLive.New do
  @moduledoc false

  use CenWeb, :live_view

  alias Cen.Employers
  alias Cen.Employers.Organization

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 lg:col-start-5">
      <h1 class="leadin-[1.3] text-title-text my-[2.1875rem] text-xl font-medium uppercase lg:text-3xl">
        <%= dgettext("orgs", "Организация") %>
      </h1>
      <.simple_form
        for={@organization_form}
        id="organization_form"
        phx-submit="update_organization"
        phx-change="validate_organization"
      >
        <fieldset>
          <legend class="leadin-[1.3] text-title-text my-[2.1875rem] text-xl uppercase lg:text-3xl">
            <%= dgettext("orgs", "Общая информация") %>
          </legend>
          <.input
            field={@organization_form[:name]}
            type="text"
            label={dgettext("orgs", "Название")}
            required
          />

          <.input
            field={@organization_form[:inn]}
            type="text"
            label={dgettext("orgs", "ИНН")}
            required
          />

          <.input
            field={@organization_form[:description]}
            type="textarea"
            label={dgettext("orgs", "Описание")}
            required
          />
        </fieldset>

        <fieldset>
          <legend class="leadin-[1.3] text-title-text my-[2.1875rem] text-xl uppercase lg:text-3xl">
            <%= dgettext("orgs", "Общая информация") %>
          </legend>
          <.input
            field={@organization_form[:phone_number]}
            type="text"
            label={dgettext("orgs", "Номер телефона")}
            required
          />

          <.input field={@organization_form[:email]} type="email" label={dgettext("orgs", "Почта")} />

          <.input field={@organization_form[:address]} type="text" label={dgettext("orgs", "Адрес")} />
        </fieldset>

        <fieldset>
          <legend class="leadin-[1.3] text-title-text my-[2.1875rem] text-xl uppercase lg:text-3xl">
            <%= dgettext("orgs", "Общая информация") %>
          </legend>
          <.input
            field={@organization_form[:website_link]}
            type="text"
            label={dgettext("orgs", "Сайт организации")}
          />
          <.input
            field={@organization_form[:social_link]}
            type="text"
            label={dgettext("orgs", "Соцсеть")}
          />
        </fieldset>

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

  def handle_event("update_organization", %{"organization" => organization_params}, socket) do
    current_user = socket.assigns.current_user

    case Employers.create_organization_for(current_user, organization_params) do
      {:ok, _organization} ->
        {:noreply, put_flash(socket, :info, dgettext("orgs", "Организация успешно создана."))}

      {:error, changeset} ->
        {:noreply, assign(socket, organization_form: to_form(changeset))}
    end
  end
end
