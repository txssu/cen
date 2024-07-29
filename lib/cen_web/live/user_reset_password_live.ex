defmodule CenWeb.UserResetPasswordLive do
  @moduledoc false
  use CenWeb, :live_view

  alias Cen.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="col-span-4 sm:col-span-2 sm:col-start-2 lg:col-span-4 lg:col-start-5">
      <h1 class="text-accent leading-[1.2] mb-9 text-center text-3xl font-medium uppercase">
        <%= dgettext("users", "Восстановление пароля") %>
      </h1>

      <.simple_form
        for={@form}
        id="reset_password_form"
        phx-submit="reset_password"
        phx-change="validate"
      >
        <.error :if={@form.errors != []}>
          <%= dgettext("users", "Упс, что-то пошло не так! Пожалуйста, проверьте ошибки ниже.") %>
        </.error>

        <.input
          field={@form[:password]}
          type="password"
          label={dgettext("users", "Новый пароль")}
          required
        />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label={dgettext("users", "Повторите новый пароль")}
          required
        />
        <:actions>
          <.arrow_button class="mx-auto">
            <%= dgettext("users", "Сохранить") %>
          </.arrow_button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _assigns ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  @impl Phoenix.LiveView
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("users", "Пароль успешно обновлён"))
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, dgettext("users", "Ссылка для сброса пароля недействительна или срок ее действия истек"))
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end
