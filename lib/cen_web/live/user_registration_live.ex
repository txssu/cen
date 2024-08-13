defmodule CenWeb.UserRegistrationLive do
  @moduledoc false
  use CenWeb, :live_view

  import CenWeb.ExtraFormsComponents
  import CenWeb.Gettext

  alias Cen.Accounts
  alias Cen.Accounts.User

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 sm:col-span-2 sm:col-start-2 lg:col-span-4 lg:col-start-5">
      <.header header_kind="blue_center">
        <%= dgettext("users", "Регистрация") %>
      </.header>
      <div class="mt-[2.1875rem]">
        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
        >
          <.error :if={@check_errors}>
            <%= dgettext("forms", "Oops, something went wrong! Please check the errors below.") %>
          </.error>

          <div class="mb-[2.8125rem]">
            <.radio
              legend={dgettext("users", "Роль")}
              field={@form[:role]}
              options={[
                {dgettext("users", "Соискатель"), "applicant"},
                {dgettext("users", "Работодатель"), "employer"}
              ]}
            />
          </div>

          <.input
            field={@form[:fullname]}
            type="text"
            placeholder={dgettext("users", "ФИО")}
            required
          />

          <.input
            :if={@form[:role].value == "applicant" or @form[:role].value == :applicant}
            field={@form[:birthdate]}
            type="text"
            onfocus="(this.type='date')"
            onblur="(this.type='text')"
            placeholder={dgettext("users", "Дата рождения")}
            required
          />

          <.input
            field={@form[:email]}
            type="email"
            placeholder={dgettext("users", "Почта")}
            required
          />
          <.input
            field={@form[:phone_number]}
            type="text"
            placeholder={dgettext("users", "Номер телефона")}
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            placeholder={dgettext("users", "Пароль")}
            required
          />

          <:actions>
            <.arrow_button class="mx-auto">
              <%= dgettext("users", "Зарегистрироваться") %>
            </.arrow_button>
          </:actions>
        </.simple_form>

        <div class="mt-[1.125rem] space-y-2.5 text-center">
          <p>
            <%= dgettext("users", "Уже есть аккаунт?") %>
            <.regular_link href={~p"/users/log_in"} text={dgettext("users", "Войти")} />
          </p>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
