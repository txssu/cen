defmodule CenWeb.UserLoginLive do
  @moduledoc false
  use CenWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 sm:col-span-2 sm:col-start-2 lg:col-span-4 lg:col-start-5">
      <.header header_kind="blue_center">
        <%= dgettext("users", "Вход") %>
      </.header>

      <div class="mt-[2.1875rem]">
        <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
          <.input
            field={@form[:email]}
            type="email"
            placeholder={dgettext("users", "Почта")}
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
              <%= dgettext("users", "Войти") %>
            </.arrow_button>
          </:actions>
        </.simple_form>

        <div class="mt-[1.125rem] space-y-2.5 text-center">
          <p>
            <%= dgettext("users", "Нет аккаунта?") %>
            <.regular_link
              navigate={~p"/users/register"}
              text={dgettext("users", "Зарегистрироваться")}
            />
          </p>
          <p>
            <.regular_link
              href={~p"/users/reset_password"}
              text={dgettext("users", "Я не помню пароль")}
            />
          </p>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
