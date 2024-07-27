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
          <.button class="flex-grow-0 bg-accent-hover uppercase py-[0.9375rem] text-title-text px-5 text-nowrap">
            <%= dgettext("users", "Удалить аккаунт") %>
          </.button>
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
end
