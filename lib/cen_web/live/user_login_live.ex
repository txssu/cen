defmodule CenWeb.UserLoginLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.PCKE

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <.header header_kind="blue_center">
        {dgettext("users", "Вход")}
      </.header>

      <div class="mt-9">
        <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
          <.input field={@form[:email]} type="email" placeholder={dgettext("users", "Почта")} implicit_required />
          <.input field={@form[:password]} type="password" placeholder={dgettext("users", "Пароль")} implicit_required />

          <:actions>
            <.arrow_button class="mx-auto">
              {dgettext("users", "Войти")}
            </.arrow_button>
          </:actions>
        </.simple_form>

        <div class="mt-8">
          <p class="text-center text-lg uppercase">{gettext("или")}</p>
        </div>

        <div class="max-w-60 mx-auto mt-4">
          <CenWeb.VKIDComponent.one_tap code={@vkid_code} state={@vkid_state} />
        </div>

        <div class="mt-8 space-y-2.5 text-center">
          <p>
            {dgettext("users", "Нет аккаунта?")}
            <.regular_link navigate={~p"/users/register"} text={dgettext("users", "Зарегистрироваться")} />
          </p>
          <p>
            <.regular_link navigate={~p"/users/reset_password"} text={dgettext("users", "Я не помню пароль")} />
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

    {:ok,
     socket
     |> assign_vkid_data()
     |> assign(form: form), temporary_assigns: [form: form]}
  end

  defp assign_vkid_data(socket) do
    {state, code} = PCKE.start_challenge()
    assign(socket, vkid_state: state, vkid_code: code)
  end
end
