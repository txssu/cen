defmodule CenWeb.UserConfirmationInstructionsLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-4 lg:col-start-5">
      <.header header_kind="blue_center">
        <%= dgettext("users", "Подтверждение аккаунта") %>
      </.header>

      <div class="my-10">
        <p>
          <%= dgettext("users", "Не пришло письмо?") %>
        </p>
        <p>
          <%= dgettext("users", "Мы отправим новую ссылку для подтверждения") %>
        </p>
      </div>

      <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input
          field={@form[:email]}
          type="email"
          placeholder={dgettext("users", "Почта")}
          implicit_required
        />
        <:actions>
          <.arrow_button class="mx-auto">
            <%= dgettext("users", "Отправить") %>
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
  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
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
