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

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

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
    host = Application.get_env(:cen, :vk_id_redirect_host)

    if user = Accounts.get_user_by_vkid_data(params, host <> ~p"/users/auth/vkid") do
      redirect_to = if user.role == nil, do: ~p"/users/choose_role"

      conn
      |> put_flash(:info, dgettext("users", "Вы успешно вошли через VK ID."))
      |> UserAuth.log_in_user(user, %{}, redirect_to)
    else
      conn
      |> put_flash(:error, dgettext("users", "Во время входа произошла ошибка."))
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
