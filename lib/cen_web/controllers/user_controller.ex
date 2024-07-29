defmodule CenWeb.UserController do
  use CenWeb, :controller

  alias Cen.Accounts
  alias CenWeb.UserAuth

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    user = conn.assigns.current_user

    unauthed_conn =
      conn
      |> UserAuth.log_out_user()
      |> put_flash(:info, dgettext("users", "Аккаунт успешно удалён."))

    user && Accounts.delete_user(user)

    unauthed_conn
  end
end
