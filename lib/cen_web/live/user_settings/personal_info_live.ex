defmodule CenWeb.UserSettings.PersonalInfoLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts
  alias CenWeb.UserSettings.Components

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Components.navigation />

    <.header class="text-center">
      Personal account info
      <:subtitle>Manage your account fullname, phone number and other settings</:subtitle>
    </.header>

    <div>
      <.simple_form
        for={@personal_info_form}
        id="personal_info_form"
        phx-submit="update_personal_info"
        phx-change="validate_personal_info"
      >
        <.input
          field={@personal_info_form[:fullname]}
          type="text"
          label={dgettext("users", "Fullname")}
          required
        />
        <.input
          field={@personal_info_form[:birthdate]}
          type="date"
          label={dgettext("users", "Birthdate")}
          required
        />
        <.input
          field={@personal_info_form[:phone_number]}
          type="text"
          label={dgettext("users", "Phone number")}
          required
        />
        <:actions>
          <.button phx-disable-with="Changing...">
            <%= dgettext("users", "Update personal info") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    personal_info_changeset = Accounts.change_user_personal_info(user)

    socket =
      assign(socket, :personal_info_form, to_form(personal_info_changeset))

    {:ok, socket}
  end
end
