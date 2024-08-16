defmodule CenWeb.UserForgotPasswordLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 sm:col-span-2 sm:col-start-2 lg:col-span-4 lg:col-start-5">
      <.header header_kind="blue_center">
        <%= dgettext("users", "Восстановление пароля") %>
      </.header>

      <p class="mt-10 mb-12">
        <%= dgettext(
          "users",
          "Введите адрес электронной почты от вашей учётной записи. На него мы вышлем ссылку для сброса пароля."
        ) %>
      </p>

      <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
        <.input
          field={@form[:email]}
          type="email"
          placeholder={dgettext("users", "Почта")}
          implicit_required
        />
        <:actions>
          <.arrow_button class="mx-auto">
            <%= dgettext("users", "Сбросить пароль") %>
          </.arrow_button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  @impl Phoenix.LiveView
  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      dgettext(
        "users",
        "Если ваш адрес электронной почты есть в нашей системе, вы вскоре получите инструкции по сбросу пароля."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
