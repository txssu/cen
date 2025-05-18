defmodule CenWeb.FetchCookiesConsentPlug do
  @moduledoc """
  Set a CSP nonce for the current request.
  """

  @behaviour Plug

  import Plug.Conn

  @cookies_consent_cookie "cookies_consent"

  @impl Plug
  def init(options), do: options

  @impl Plug
  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    if conn.req_cookies[@cookies_consent_cookie] == "accepted" do
      put_session(conn, :cookies_consent_accepted, true)
    else
      put_session(conn, :cookies_consent_accepted, false)
    end
  end

  @spec on_mount(atom(), Phoenix.LiveView.unsigned_params(), map(), Phoenix.Socket.t()) :: {:cont | :halt, Phoenix.Socket.t()}
  def on_mount(:default, _params, session, socket) do
    consent_result =
      if socket.assigns.current_user,
        do: true,
        else: session["cookies_consent_accepted"]

    {:cont, Phoenix.Component.assign(socket, :cookies_consent_accepted, consent_result)}
  end
end
