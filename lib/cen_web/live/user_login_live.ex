defmodule CenWeb.UserLoginLive do
  @moduledoc false
  use CenWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 sm:col-span-2 sm:col-start-2 lg:col-span-4 lg:col-start-5">
      <h1 class="text-accent leading-[1.2] text-center text-3xl font-medium uppercase">
        <%= dgettext("users", "Вход") %>
      </h1>

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
            <.button
              phx-disable-with="Вход..."
              class="mx-auto mt-[1.875rem] uppercase text-[0.9375rem] shadow-default-1"
            >
              <.icon class="h-[1.875rem] bg-white rounded-full shadow-icon" name="cen-arrow-right" />
              <span>
                <%= dgettext("users", "Войти") %>
              </span>
            </.button>
          </:actions>
        </.simple_form>

        <article class="mt-[1.125rem] space-y-2.5 text-center">
          <p>
            <%= dgettext("users", "Нет аккаунта?") %>
            <.link class="link" href={~p"/users/register"}>
              <%= dgettext("users", "Зарегистрироваться") %>
            </.link>
          </p>
          <p>
            <.link class="link" href={~p"/users/reset_password"}>
              <%= dgettext("users", "Я не помню пароль") %>
            </.link>
          </p>
        </article>
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
