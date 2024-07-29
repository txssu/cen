defmodule CenWeb.UserSettings.CredentialsLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts
  alias CenWeb.UserSettings.Components

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 lg:col-span-3">
      <Components.navigation current_page={:credentials} />
    </div>

    <div class="col-span-4 lg:col-start-5">
      <div>
        <h2 class="leadin-[1.3] text-title-text my-[2.1875rem] text-xl font-medium uppercase lg:text-3xl">
          <%= dgettext("users", "Обновить почту") %>
        </h2>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input
            field={@email_form[:email]}
            type="email"
            label={dgettext("users", "Почта")}
            required
          />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label={dgettext("users", "Текущий пароль")}
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.arrow_button>
              <%= dgettext("users", "Сохранить") %>
            </.arrow_button>
          </:actions>
        </.simple_form>
      </div>

      <h2 class="leadin-[1.3] text-title-text mt-[4.375rem] mb-[2.1875rem] text-xl font-medium uppercase lg:mt-[7.3125rem] lg:text-3xl">
        <%= dgettext("users", "Обновить пароль") %>
      </h2>

      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input
            field={@password_form[:password]}
            type="password"
            label={dgettext("users", "Новый пароль")}
            required
          />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label={dgettext("users", "Подтвердите новый пароль")}
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label={dgettext("users", "Текущий пароль")}
            id="current_password_for_password"
            value={@current_password}
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
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, dgettext("users", "Почта успешно обновлена."))

        :error ->
          put_flash(
            socket,
            :error,
            dgettext("users", "Ссылка для изменения электронной почты недействительна или срок ее действия истек.")
          )
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings/credentials")}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = dgettext("users", "На новый адрес отправлена ссылка для подтверждения изменения электронной почты.")
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
