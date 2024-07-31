defmodule CenWeb.UserSettings.PersonalInfoLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts
  alias CenWeb.UserSettings.Components

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 lg:col-span-3">
      <Components.navigation current_page={:personal} />
    </div>

    <div class="col-span-4 lg:col-start-5">
      <div class="mt-[2.1875rem] gap-[1.875rem] mb-2.5 flex lg:mb-[3.4375rem]">
        <div class="flex-shrink-0 flex-grow-0">
          <div class="w-[4.375rem] h-[4.375rem] bg-accent inline-block rounded-full lg:w-[6.75rem] lg:h-[6.75rem]">
          </div>
        </div>
        <div class="flex flex-grow-0 flex-col justify-center">
          <.link patch={~p"/users/settings/personal/delete"}>
            <.button class="flex-grow-0 bg-accent-hover uppercase py-[0.9375rem] text-title-text px-5 text-nowrap">
              <%= dgettext("users", "Удалить аккаунт") %>
            </.button>
          </.link>
        </div>
      </div>

      <div class="col-span-4">
        <.simple_form
          for={@personal_info_form}
          id="personal_info_form"
          phx-submit="update_personal_info"
          phx-change="validate_personal_info"
        >
          <.input
            field={@personal_info_form[:fullname]}
            type="text"
            placeholder={dgettext("users", "ФИО")}
            required
          />
          <.input
            :if={@user_role == :applicant}
            field={@personal_info_form[:birthdate]}
            type="date"
            placeholder={dgettext("users", "Дата рождения")}
            required
          />
          <.input
            field={@personal_info_form[:phone_number]}
            type="text"
            placeholder={dgettext("users", "Номер телефона")}
            required
          />
          <:actions>
            <.arrow_button>
              <%= dgettext("users", "Сохранить") %>
            </.arrow_button>
          </:actions>
        </.simple_form>
      </div>
    </div>

    <.modal
      :if={@live_action == :confirm_delete_user}
      show
      id="confirm_delete_user"
      on_cancel={JS.navigate(~p"/users/settings/personal")}
    >
      <p>
        <%= dgettext("users", "Вы действительно хотите удалить пользователя?") %>
      </p>
      <div class="w-fit">
        <.link href={~p"/users"} method="delete">
          <.arrow_button class="mt-4">
            <%= dgettext("users", "Да, удалить") %>
          </.arrow_button>
        </.link>
      </div>
    </.modal>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    personal_info_changeset = Accounts.change_user_personal_info(user)

    socket =
      assign(socket,
        personal_info_form: to_form(personal_info_changeset),
        user_role: user.role
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_personal_info", %{"user" => user_params}, socket) do
    personal_info_form =
      socket.assigns.current_user
      |> Accounts.change_user_personal_info(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, personal_info_form: personal_info_form)}
  end

  def handle_event("update_personal_info", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_personal_info(user, user_params) do
      {:ok, user} ->
        personal_info_form =
          user
          |> Accounts.change_user_personal_info(user_params)
          |> to_form()

        {:noreply, assign(socket, personal_info_form: personal_info_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, personal_info_form: to_form(changeset))}
    end
  end
end
