defmodule CenWeb.UserLoginLive do
  @moduledoc false
  use CenWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 sm:col-span-2 sm:col-start-2 lg:col-start-5 lg:sm:col-span-4">
      <h1 class="text-accent text-[30px] leading-[1.2] text-center font-medium uppercase">
        <%= dgettext("auth", "Вход") %>
      </h1>

      <div class="mt-[35px]">
        <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
          <.input field={@form[:email]} type="email" placeholder={dgettext("auth", "Почта")} required />
          <.input
            field={@form[:password]}
            type="password"
            placeholder={dgettext("auth", "Пароль")}
            required
          />

          <:actions>
            <.button
              phx-disable-with="Вход..."
              class="mx-auto mt-[30px] uppercase text-[15px] shadow-default-1"
            >
              <.icon class="h-[30px] bg-white rounded-full shadow-icon" name="cen-arrow-right" />
              <span>
                <%= dgettext("auth", "Войти") %>
              </span>
            </.button>
          </:actions>
        </.simple_form>

        <article class="mt-[18px] space-y-2.5 text-center">
          <p>
            <%= dgettext("auth", "Нет аккаунта?") %>
            <.link class="link" href={~p"/users/register"}>
              <%= dgettext("auth", "Зарегистрироваться") %>
            </.link>
          </p>
          <p>
            <.link class="link" href={~p"/users/reset_password"}>
              <%= dgettext("auth", "Я не помню пароль") %>
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
