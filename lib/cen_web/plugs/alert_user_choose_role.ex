defmodule CenWeb.Plugs.AlertUserChooseRole do
  @moduledoc false
  @behaviour Plug

  use CenWeb, :verified_routes
  use Gettext, backend: CenWeb.Gettext

  import Phoenix.Controller

  @impl Plug
  def init(options), do: options

  @impl Plug
  def call(conn, _options) do
    user = conn.assigns.current_user

    if user && user.role == nil do
      put_flash(conn, :error, dgettext("users", "Вам необходимо выбрать роль"))
    else
      conn
    end
  end
end
