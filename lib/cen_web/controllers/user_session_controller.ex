defmodule CenWeb.UserSessionController do
  use CenWeb, :controller

  alias Cen.Accounts
  alias CenWeb.UserAuth

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, dgettext("users", "Аккаунт успешно создан."))
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings/credentials")
    |> create(params, dgettext("users", "Пароль успешно обновлен!"))
  end

  def create(conn, params) do
    create(conn, params, dgettext("users", "С возвращением!"))
  end

  defp create(conn, %{"user" => %{"vk_id" => encrypted_vk_id} = user_params}, info) do
    with {:ok, vk_id} <- Phoenix.Token.decrypt(CenWeb.Endpoint, "user vk id", encrypted_vk_id),
         %Accounts.User{} = user <- Accounts.get_user_by_vk_id(vk_id) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      _any_error ->
        conn
        |> put_flash(:error, dgettext("users", "Во время авторизации произошла ошибка, воспользуйтесь другим способом входа"))
        |> redirect(to: ~p"/users/log_in")
    end
  end

  defp create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}, info) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, dgettext("users", "Неверный адрес электронной почты или пароль."))
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  @spec auth_vkid(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def auth_vkid(conn, params) do
    case Accounts.fetch_user_from_vk(params, url(~p"/users/auth/vkid")) do
      {:ok, user} ->
        # TODO: Add redirect to /choose_role page
        conn
        |> put_flash(:info, dgettext("users", "Вы успешно вошли через VK ID."))
        |> UserAuth.log_in_user(user, %{})

      {:error, %Ecto.Changeset{} = changeset} ->
        vk_id = Accounts.save_invalid_params(changeset)

        encrypted_vk_id = Phoenix.Token.encrypt(CenWeb.Endpoint, "user vk id", vk_id)

        conn
        |> put_flash(:error, "Отредактируйте данные")
        |> redirect(to: ~p"/users/register?vk_id=#{encrypted_vk_id}")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "В данный момент вход через ВК не работает, попробуйте позже.")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn
    |> put_flash(:info, dgettext("users", "Вы вышли из системы."))
    |> UserAuth.log_out_user()
  end
end
